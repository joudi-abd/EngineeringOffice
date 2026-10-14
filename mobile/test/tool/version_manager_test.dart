import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/version_manager.dart';

const _pubspecTemplate = '''
name: sample_app
description: Sample.
publish_to: 'none'

# The version below is the single source of truth.
version: %V% # keep this comment

environment:
  sdk: ^3.0.0
''';

String _dartBin() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final f = File('$root/bin/dart');
    if (f.existsSync()) return f.path;
  }
  return 'dart';
}

Directory _project(String version) {
  final dir = Directory.systemTemp.createTempSync('ufuq_version_');
  File('${dir.path}/pubspec.yaml')
      .writeAsStringSync(_pubspecTemplate.replaceFirst('%V%', version));
  return dir;
}

Future<ProcessResult> _cli(Directory project, List<String> args) {
  final script = '${Directory.current.path}/tool/version.dart';
  return Process.run(_dartBin(), [script, ...args, '--project', project.path]);
}

void main() {
  late Directory dir;
  late VersionManager vm;

  Future<Outcome> run(Operation op, {bool dry = false}) =>
      vm.execute(op, dryRun: dry);

  void start(String version) {
    dir = _project(version);
    vm = VersionManager(dir);
    vm.initLedger();
  }

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('next', () {
    test('bumps the last part by exactly 1 and the code by 1', () async {
      start('1.0.4+10');
      final o = await run(NextOp());
      expect(o.before.build, '1.0.4+10');
      expect(o.after.build, '1.0.5+11');
      expect(vm.readVersion().build, '1.0.5+11');
    });

    test('1.0.9 becomes 1.0.10 (numeric, not text)', () async {
      start('1.0.9+9');
      await run(NextOp());
      expect(vm.readVersion().name, '1.0.10');
    });

    test('keeps the rest of pubspec.yaml byte for byte', () async {
      start('1.0.4+10');
      final before = File('${dir.path}/pubspec.yaml').readAsStringSync();
      await run(NextOp());
      final after = File('${dir.path}/pubspec.yaml').readAsStringSync();
      expect(after, before.replaceFirst('1.0.4+10', '1.0.5+11'));
      expect(after, contains('# keep this comment'));
    });
  });

  group('set', () {
    test('sets the name by hand and still raises the code', () async {
      start('1.0.4+10');
      final o = await run(SetOp('1.0.12'));
      expect(o.after.build, '1.0.12+11');
    });

    test('lowering the visible name keeps a valid ascending code', () async {
      start('1.0.4+10');
      await run(SetOp('1.0.12'));
      final o = await run(SetOp('1.0.8'));
      expect(o.after.name, '1.0.8');
      expect(o.after.code, 12);
      expect(o.after.code, greaterThan(o.before.code));
    });

    test('an explicit code must be above everything issued', () async {
      start('1.0.4+10');
      final o = await run(SetOp('1.0.5', code: 500));
      expect(o.after.build, '1.0.5+500');
      await expectLater(
        run(SetOp('1.0.6', code: 500)),
        throwsA(isA<VersionError>()),
      );
      await expectLater(
        run(SetOp('1.0.6', code: 20)),
        throwsA(isA<VersionError>()),
      );
      expect(vm.readVersion().build, '1.0.5+500');
    });

    test('setting the same name again is a no-op', () async {
      start('1.0.4+10');
      final o = await run(SetOp('1.0.4'));
      expect(o.changed, isFalse);
      expect(vm.readVersion().build, '1.0.4+10');
    });
  });

  group('code', () {
    test('raises only the code (store already holds a higher one)', () async {
      start('1.0.4+10');
      final o = await run(CodeOp(80));
      expect(o.after.build, '1.0.4+80');
      final next = await run(NextOp());
      expect(next.after.build, '1.0.5+81');
    });

    test('refuses a code that is not above the ledger', () async {
      start('1.0.4+10');
      await expectLater(run(CodeOp(10)), throwsA(isA<VersionError>()));
      await expectLater(run(CodeOp(3)), throwsA(isA<VersionError>()));
    });
  });

  group('invalid input', () {
    test('rejects bad names', () async {
      start('1.0.4+10');
      for (final bad in [
        '',
        '1.0',
        '1.0.',
        '1.1.0',
        '2.0.1',
        '1.0.-1',
        '1.0.x',
        '1.0.01',
        '1.0.4-beta',
        'v1.0.4',
        '1.0.4+7',
        ' 1.0.4',
        '1.0.4.1',
        '1.0.99999999999',
      ]) {
        await expectLater(
          run(SetOp(bad)),
          throwsA(isA<VersionError>()),
          reason: 'name "$bad" must be rejected',
        );
      }
      expect(vm.readVersion().build, '1.0.4+10');
    });

    test('rejects bad codes', () async {
      start('1.0.4+10');
      for (final bad in [0, -5, 2100000000]) {
        await expectLater(
          run(CodeOp(bad)),
          throwsA(isA<VersionError>()),
          reason: 'code $bad must be rejected',
        );
      }
    });

    test('refuses a pubspec whose code was lowered by hand', () async {
      start('1.0.4+10');
      await run(NextOp()); // ledger floor = 11
      File('${dir.path}/pubspec.yaml')
          .writeAsStringSync(_pubspecTemplate.replaceFirst('%V%', '1.0.5+3'));
      await expectLater(
        run(NextOp()),
        throwsA(
          isA<VersionError>().having((e) => e.exitCode, 'exit', exitConflict),
        ),
      );
      expect(vm.check(), isNotEmpty);
    });

    test('refuses a pubspec with an unsupported version line', () async {
      dir = _project('2.3.4+5');
      vm = VersionManager(dir);
      await expectLater(run(NextOp()), throwsA(isA<VersionError>()));
    });
  });

  group('re-running a release', () {
    test('same release id does not bump twice', () async {
      start('1.0.4+10');
      final first = await run(NextOp(releaseId: 'run-77'));
      final again = await run(NextOp(releaseId: 'run-77'));
      expect(first.after.build, '1.0.5+11');
      expect(again.after.build, '1.0.5+11');
      expect(again.alreadyApplied, isTrue);
      expect(again.changed, isFalse);
      expect(vm.readVersion().build, '1.0.5+11');
    });

    test('a different release id bumps again', () async {
      start('1.0.4+10');
      await run(NextOp(releaseId: 'run-77'));
      final o = await run(NextOp(releaseId: 'run-78'));
      expect(o.after.build, '1.0.6+12');
    });

    test('an interrupted run is repaired without a second bump', () async {
      start('1.0.4+10');
      await run(NextOp(releaseId: 'run-9'));
      // Simulate a crash after the ledger was written but before pubspec was.
      File('${dir.path}/pubspec.yaml')
          .writeAsStringSync(_pubspecTemplate.replaceFirst('%V%', '1.0.4+10'));
      final o = await run(NextOp(releaseId: 'run-9'));
      expect(o.repaired, isTrue);
      expect(vm.readVersion().build, '1.0.5+11');
      final ledger = jsonDecode(vm.stateFile.readAsStringSync()) as Map;
      expect(ledger['code_floor'], 11);
    });
  });

  group('dry-run', () {
    test('changes no file and creates no lock or ledger', () async {
      dir = _project('1.0.4+10');
      vm = VersionManager(dir); // no ledger on purpose
      final before = File('${dir.path}/pubspec.yaml').readAsStringSync();
      final o = await run(NextOp(), dry: true);
      expect(o.after.build, '1.0.5+11');
      expect(o.written, isFalse);
      expect(File('${dir.path}/pubspec.yaml').readAsStringSync(), before);
      expect(vm.stateFile.existsSync(), isFalse);
      expect(File('${dir.path}/tool/.version.lock').existsSync(), isFalse);
    });

    test('predicts exactly what the real run then does', () async {
      start('1.0.4+10');
      final preview = await run(SetOp('1.0.2'), dry: true);
      final real = await run(SetOp('1.0.2'));
      expect(real.after, preview.after);
    });
  });

  group('command line', () {
    test('show / next / set end to end, with exit codes', () async {
      dir = _project('1.0.4+10');
      expect((await _cli(dir, ['init'])).exitCode, 0);

      final show = await _cli(dir, ['show', '--name']);
      expect((show.stdout as String).trim(), '1.0.4');

      final dry = await _cli(dir, ['dry-run', 'next']);
      expect(dry.exitCode, 0);
      expect(dry.stdout, contains('nothing was written'));
      expect(
        (await _cli(dir, ['show', '--build-number'])).stdout.toString().trim(),
        '10',
      );

      expect((await _cli(dir, ['next'])).exitCode, 0);
      expect((await _cli(dir, ['set', '1.0.2'])).exitCode, 0);
      final code = await _cli(dir, ['show', '--build-number']);
      expect((code.stdout as String).trim(), '12');
      expect((await _cli(dir, ['check'])).exitCode, 0);
    });

    test('invalid input exits with 1 and changes nothing', () async {
      dir = _project('1.0.4+10');
      await _cli(dir, ['init']);
      for (final args in [
        ['set', '1.0.x'],
        ['set'],
        ['set', '1.0.5', '--code', 'abc'],
        ['next', '--code', '99'],
        ['bogus'],
        ['next', '--release-id', 'bad id!'],
      ]) {
        final r = await _cli(dir, args);
        expect(r.exitCode, 1, reason: '$args -> ${r.stderr}');
      }
      expect(VersionManager(dir).readVersion().build, '1.0.4+10');
    });

    test('parallel releases never share a versionCode', () async {
      dir = _project('1.0.0+1');
      await _cli(dir, ['init']);
      final results = await Future.wait([
        for (var i = 0; i < 6; i++) _cli(dir, ['next', '--release-id', 'p$i']),
      ]);
      expect(results.map((r) => r.exitCode), everyElement(0));
      final v = VersionManager(dir).readVersion();
      expect(v.build, '1.0.6+7');
      final ledger = jsonDecode(
        VersionManager(dir).stateFile.readAsStringSync(),
      ) as Map<String, Object?>;
      final codes = [
        for (final h in ledger['history']! as List)
          if ((h as Map)['op'] != 'init') (h['to'] as String).split('+').last,
      ];
      expect(codes.toSet().length, codes.length);
    });

    test('parallel runs with the same release id bump once', () async {
      dir = _project('1.0.0+1');
      await _cli(dir, ['init']);
      final results = await Future.wait([
        for (var i = 0; i < 5; i++) _cli(dir, ['next', '--release-id', 'same']),
      ]);
      expect(results.map((r) => r.exitCode), everyElement(0));
      expect(VersionManager(dir).readVersion().build, '1.0.1+2');
    });
  });

  group('metadata verification script', () {
    // A stand-in for aapt that prints what the manifest of an APK would contain.
    String fakeAapt(Directory d, String name, String code, String id) {
      final f = File('${d.path}/fake_aapt')
        ..writeAsStringSync(
          "#!/usr/bin/env bash\n"
          "echo \"package: name='$id' versionCode='$code' versionName='$name' compileSdkVersion='36'\"\n",
        );
      Process.runSync('chmod', ['+x', f.path]);
      return f.path;
    }

    Future<ProcessResult> verify(String aapt, {String? name, String? code}) {
      final apk = File('${dir.path}/app.apk')..writeAsStringSync('x');
      final script = '${Directory.current.path}/tool/verify_apk_version.sh';
      return Process.run(
        'bash',
        [script, apk.path, ?name, ?code],
        environment: {'AAPT': aapt, 'DART': _dartBin()},
      );
    }

    test('passes when the APK carries the expected version', () async {
      dir = _project('1.0.4+10');
      final r = await verify(
        fakeAapt(dir, '1.0.4', '10', 'com.ufuq.imperium'),
        name: '1.0.4',
        code: '10',
      );
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    });

    test('fails on a different name, code, or application id', () async {
      dir = _project('1.0.4+10');
      expect(
        (await verify(
          fakeAapt(dir, '1.0.3', '10', 'com.ufuq.imperium'),
          name: '1.0.4',
          code: '10',
        )).exitCode,
        2,
      );
      expect(
        (await verify(
          fakeAapt(dir, '1.0.4', '9', 'com.ufuq.imperium'),
          name: '1.0.4',
          code: '10',
        )).exitCode,
        2,
      );
      expect(
        (await verify(
          fakeAapt(dir, '1.0.4', '10', 'com.other.app'),
          name: '1.0.4',
          code: '10',
        )).exitCode,
        2,
      );
    });
  });
}
