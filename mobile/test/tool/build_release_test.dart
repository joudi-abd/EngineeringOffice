import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Exercises tool/build_release.sh in a throw-away project with stand-ins for flutter, aapt, apksigner and
// jarsigner, so no real build is needed. A fake "apk" is a text file: "<versionName>|<versionCode>|<appId>".

String _dartBin() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final f = File('$root/bin/dart');
    if (f.existsSync()) return f.path;
  }
  return 'dart';
}

void _exec(File f, String body) {
  f.writeAsStringSync('#!/usr/bin/env bash\n$body');
  Process.runSync('chmod', ['+x', f.path]);
}

List<int> _lenField(int field, List<int> bytes) {
  final out = <int>[(field << 3) | 2];
  var n = bytes.length;
  while (n >= 0x80) {
    out.add((n & 0x7F) | 0x80);
    n >>= 7;
  }
  out.add(n);
  return [...out, ...bytes];
}

/// A protobuf-encoded manifest like the one inside an .aab (XmlNode > XmlElement > XmlAttribute).
List<int> _protoManifest(String id, String code, String name) {
  List<int> attr(String n, String v) => _lenField(4, [
    ..._lenField(2, n.codeUnits),
    ..._lenField(3, v.codeUnits),
  ]);
  final element = [
    ..._lenField(3, 'manifest'.codeUnits),
    ...attr('package', id),
    ...attr('versionCode', code),
    ...attr('versionName', name),
  ];
  return _lenField(1, element);
}

void main() {
  late Directory dir;
  late Directory tools;
  late Map<String, String> env;

  File dist(String name) => File('${dir.path}/dist/$name');
  String pubspec() => File('${dir.path}/pubspec.yaml').readAsStringSync();
  String ledger() =>
      File('${dir.path}/tool/release_state.json').readAsStringSync();

  Future<ProcessResult> build(List<String> args, {Map<String, String>? more}) =>
      Process.run(
        'bash',
        ['${dir.path}/tool/build_release.sh', ...args],
        environment: {...env, ...?more},
        workingDirectory: dir.path,
      );

  void project(String version) {
    dir = Directory.systemTemp.createTempSync('ufuq_release_');
    File('${dir.path}/pubspec.yaml')
        .writeAsStringSync('name: sample\nversion: $version\n');
    Directory('${dir.path}/tool').createSync();
    for (final name in [
      'version.dart',
      'version_manager.dart',
      'verify_apk_version.sh',
      'build_release.sh',
      '_android_tools.sh',
      'aab_manifest.py',
    ]) {
      File('${Directory.current.path}/tool/$name')
          .copySync('${dir.path}/tool/$name');
    }
    Process.runSync(_dartBin(), [
      '${dir.path}/tool/version.dart',
      'init',
      '--project',
      dir.path,
    ]);

    tools = Directory('${dir.path}/fakebin')..createSync();
    // fake flutter: writes the outputs the real tool would, carrying the pubspec version (or FAKE_VERSION).
    _exec(File('${tools.path}/flutter'), r'''
set -e
v="${FAKE_VERSION:-$(sed -n 's/^version: //p' pubspec.yaml)}"
name="${v%+*}"; code="${v#*+}"
id="${FAKE_APP_ID:-com.ufuq.imperium}"
[[ "${FAKE_FLUTTER_FAIL:-}" == 1 ]] && { echo "boom" >&2; exit 1; }
out=build/app/outputs/flutter-apk
mkdir -p "$out" build/app/outputs/bundle/release
if [[ "$1 $2" == "build apk" ]]; then
  if [[ " $* " == *" --split-per-abi "* ]]; then
    echo "$name|$((code + 1000))|$id" > "$out/app-armeabi-v7a-release.apk"
    echo "$name|$((code + 2000))|$id" > "$out/app-arm64-v8a-release.apk"
    echo "$name|$((code + 4000))|$id" > "$out/app-x86_64-release.apk"
  else
    echo "$name|$code|$id" > "$out/app-release.apk"
  fi
else
  cp "$FAKE_AAB" build/app/outputs/bundle/release/app-release.aab
fi
''');
    _exec(File('${tools.path}/aapt'), r'''
IFS='|' read -r n c i < "$3"
echo "package: name='$i' versionCode='$c' versionName='$n' compileSdkVersion='36'"
''');
    _exec(File('${tools.path}/apksigner'), r'''
[[ "${FAKE_SIGN_FAIL:-}" == 1 ]] && { echo "DOES NOT VERIFY" >&2; exit 1; }
exit 0
''');
    _exec(File('${tools.path}/jarsigner'), r'''
[[ "${FAKE_SIGN_FAIL:-}" == 1 ]] && exit 1
echo "jar verified."
''');

    env = {
      'FLUTTER': '${tools.path}/flutter',
      'AAPT': '${tools.path}/aapt',
      'APKSIGNER': '${tools.path}/apksigner',
      'JARSIGNER': '${tools.path}/jarsigner',
      'DART': _dartBin(),
    };
  }

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test(
    'universal APK is named UFUQ-<versionName>.apk and is byte-identical',
    () async {
      project('1.0.8+12');
      final r = await build([]);
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      final out = dist('UFUQ-1.0.8.apk');
      expect(out.existsSync(), isTrue);
      expect(
        out.readAsBytesSync(),
        File('${dir.path}/build/app/outputs/flutter-apk/app-release.apk')
            .readAsBytesSync(),
      );
      expect(dist('UFUQ-1.0.8.apk.sha256').existsSync(), isTrue);
      // exactly one collected artifact, nothing named after the old file
      expect(
        Directory('${dir.path}/dist')
            .listSync()
            .map((e) => e.path.split('/').last),
        unorderedEquals(['UFUQ-1.0.8.apk', 'UFUQ-1.0.8.apk.sha256']),
      );
    },
  );

  test('a build never touches the version', () async {
    project('1.0.8+12');
    final pubBefore = pubspec();
    final ledgerBefore = ledger();
    await build([]);
    await build(['--split-per-abi']);
    expect(pubspec(), pubBefore);
    expect(ledger(), ledgerBefore);
  });

  test('uses the lowered name after a manual reset', () async {
    project('1.0.12+20');
    await Process.run(_dartBin(), [
      '${dir.path}/tool/version.dart',
      'set',
      '1.0.8',
      '--project',
      dir.path,
    ]);
    final r = await build([]);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    expect(dist('UFUQ-1.0.8.apk').existsSync(), isTrue);
    expect(dist('UFUQ-1.0.8.apk').readAsStringSync(), startsWith('1.0.8|21|'));
  });

  test(
    'split APKs get one name per ABI and the ABI-adjusted versionCode',
    () async {
      project('1.0.8+12');
      final r = await build(['--split-per-abi']);
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect(
        dist('UFUQ-1.0.8-armeabi-v7a.apk').readAsStringSync(),
        contains('|1012|'),
      );
      expect(
        dist('UFUQ-1.0.8-arm64-v8a.apk').readAsStringSync(),
        contains('|2012|'),
      );
      expect(
        dist('UFUQ-1.0.8-x86_64.apk').readAsStringSync(),
        contains('|4012|'),
      );
      expect(dist('UFUQ-1.0.8.apk').existsSync(), isFalse);
    },
  );

  test(
    '--aab collects UFUQ-<versionName>.aab after reading its manifest',
    () async {
      project('1.0.8+12');
      final stage = File('${dir.path}/fixture.zip');
      final manifest = File('${dir.path}/manifest.bin')
        ..writeAsBytesSync(_protoManifest('com.ufuq.imperium', '12', '1.0.8'));
      final z = Process.runSync('python3', [
        '-c',
        'import zipfile,sys; z=zipfile.ZipFile(sys.argv[1],"w"); z.write(sys.argv[2],"base/manifest/AndroidManifest.xml"); z.close()',
        stage.path,
        manifest.path,
      ]);
      expect(z.exitCode, 0, reason: '${z.stderr}');
      final r = await build(['--aab'], more: {'FAKE_AAB': stage.path});
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect(dist('UFUQ-1.0.8.aab').existsSync(), isTrue);
      expect(dist('UFUQ-1.0.8.apk').existsSync(), isFalse);
    },
  );

  test(
    'refuses an output whose embedded version differs, and collects nothing',
    () async {
      project('1.0.8+12');
      final r = await build([], more: {'FAKE_VERSION': '1.0.7+12'});
      expect(r.exitCode, isNot(0));
      expect(
        r.stdout.toString() + r.stderr.toString(),
        contains('MISMATCH versionName'),
      );
      expect(dist('UFUQ-1.0.8.apk').existsSync(), isFalse);
    },
  );

  test('refuses a different application id', () async {
    project('1.0.8+12');
    final r = await build([], more: {'FAKE_APP_ID': 'com.other.app'});
    expect(r.exitCode, isNot(0));
    expect(dist('UFUQ-1.0.8.apk').existsSync(), isFalse);
  });

  test('refuses an APK whose signature does not verify', () async {
    project('1.0.8+12');
    final r = await build([], more: {'FAKE_SIGN_FAIL': '1'});
    expect(r.exitCode, isNot(0));
    expect(dist('UFUQ-1.0.8.apk').existsSync(), isFalse);
  });

  test('stops when the flutter build fails', () async {
    project('1.0.8+12');
    final r = await build([], more: {'FAKE_FLUTTER_FAIL': '1'});
    expect(r.exitCode, isNot(0));
    expect(Directory('${dir.path}/dist').existsSync(), isFalse);
  });

  test('stops when the version system reports a problem', () async {
    project('1.0.8+12');
    File('${dir.path}/tool/release_state.json').deleteSync();
    final r = await build([]);
    expect(r.exitCode, isNot(0));
    expect(Directory('${dir.path}/dist').existsSync(), isFalse);
  });

  test(
    'never overwrites a different earlier release of the same name',
    () async {
      project('1.0.8+12');
      await build([]);
      // Same visible name again but another code (e.g. after a reset): a different file.
      await Process.run(_dartBin(), [
        '${dir.path}/tool/version.dart',
        'code',
        '99',
        '--project',
        dir.path,
      ]);
      final r = await build([]);
      expect(r.exitCode, isNot(0));
      expect(r.stderr, contains('--force'));
      expect(dist('UFUQ-1.0.8.apk').readAsStringSync(), contains('|12|'));

      final forced = await build(['--force']);
      expect(forced.exitCode, 0, reason: '${forced.stdout}${forced.stderr}');
      expect(dist('UFUQ-1.0.8.apk').readAsStringSync(), contains('|99|'));
    },
  );

  test('running again with identical output is fine', () async {
    project('1.0.8+12');
    expect((await build([])).exitCode, 0);
    expect((await build([])).exitCode, 0);
  });

  test('--skip-build collects what is already built', () async {
    project('1.0.8+12');
    await build([]);
    dist('UFUQ-1.0.8.apk').deleteSync();
    dist('UFUQ-1.0.8.apk.sha256').deleteSync();
    final r = await build(['--skip-build'], more: {'FAKE_FLUTTER_FAIL': '1'});
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    expect(dist('UFUQ-1.0.8.apk').existsSync(), isTrue);
  });

  test('rejects unknown options', () async {
    project('1.0.8+12');
    final r = await build(['--bogus']);
    expect(r.exitCode, 1);
  });
}
