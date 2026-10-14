// CLI for the app's release versioning. See tool/README.md.
//
//   dart tool/version.dart show [--json | --name | --build-number]
//   dart tool/version.dart next [--release-id ID] [--dry-run]
//   dart tool/version.dart set 1.0.8 [--code N] [--release-id ID] [--dry-run]
//   dart tool/version.dart code N [--release-id ID] [--dry-run]
//   dart tool/version.dart dry-run next|set|code ...
//   dart tool/version.dart init | check
import 'dart:convert';
import 'dart:io';

import 'version_manager.dart';

const _usage = '''
UFUQ release versioning (source of truth: pubspec.yaml "version: 1.0.<n>+<code>")

Usage:  dart tool/version.dart <command> [options]

Commands:
  show                 Print the current versionName and versionCode.
                         --json | --name | --build-number   machine-friendly output
  next                 Next release: 1.0.<n> -> 1.0.<n+1>, versionCode = highest issued + 1.
  set <1.0.N>          Set the visible version name by hand. versionCode still goes UP.
                         --code N   also choose the versionCode (must be above every issued one)
  code <N>             Raise only the versionCode (e.g. the store already holds a higher one).
  dry-run <command>    Preview next / set / code without touching any file.
  init                 Create tool/release_state.json from pubspec.yaml if it is missing.
  check                Verify pubspec.yaml and the ledger agree and the code never went down.
  help                 This text.

Options for next / set / code:
  --release-id ID      Idempotency key for one release run (e.g. the CI run id).
                       Running again with the same ID never bumps a second time.
                       Also read from the UFUQ_RELEASE_ID environment variable.
  --dry-run, -n        Same as the dry-run command.
  --project DIR        Flutter project folder (default: the folder above tool/).
''';

Future<void> main(List<String> args) async {
  final code = await run(args, out: stdout, err: stderr);
  if (code != 0) exit(code);
}

/// Testable entry point. Returns the process exit code.
Future<int> run(
  List<String> args, {
  required IOSink out,
  required IOSink err,
}) async {
  try {
    return await _run(args, out);
  } on VersionError catch (e) {
    err.writeln('error: ${e.message}');
    return e.exitCode;
  }
}

Future<int> _run(List<String> input, IOSink out) async {
  final args = [...input];
  if (args.isEmpty ||
      args.first == 'help' ||
      args.first == '--help' ||
      args.first == '-h') {
    out.write(_usage);
    return 0;
  }

  var command = args.removeAt(0);
  var dryRun = false;
  if (command == 'dry-run') {
    if (args.isEmpty) {
      throw VersionError(
        'dry-run needs a command: next | set <1.0.N> | code <N>',
      );
    }
    dryRun = true;
    command = args.removeAt(0);
  }

  // options
  String? releaseId = Platform.environment['UFUQ_RELEASE_ID'];
  String? projectPath;
  String? codeOption;
  var json = false, onlyName = false, onlyCode = false;
  final positional = <String>[];
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String value(String flag) {
      if (i + 1 >= args.length) throw VersionError('$flag needs a value.');
      return args[++i];
    }

    switch (arg) {
      case '--dry-run' || '-n':
        dryRun = true;
      case '--release-id':
        releaseId = value(arg);
      case '--project':
        projectPath = value(arg);
      case '--code':
        codeOption = value(arg);
      case '--json':
        json = true;
      case '--name':
        onlyName = true;
      case '--build-number':
        onlyCode = true;
      default:
        if (arg.startsWith('-')) {
          throw VersionError(
            'Unknown option $arg. See: dart tool/version.dart help',
          );
        }
        positional.add(arg);
    }
  }
  if (releaseId != null) {
    releaseId = releaseId.trim();
    if (releaseId.isEmpty) releaseId = null;
  }
  if (releaseId != null &&
      !RegExp(r'^[A-Za-z0-9._:/-]{1,100}$').hasMatch(releaseId)) {
    throw VersionError(
      'Invalid release id "$releaseId". Use letters, digits and . _ : / - only.',
    );
  }

  final project = Directory(
    projectPath ?? File.fromUri(Platform.script).parent.parent.path,
  );
  final manager = VersionManager(project);

  switch (command) {
    case 'show':
      _expect(positional, 0, 'show');
      final current = manager.readVersion();
      final floor = manager.effectiveFloor(current, manager.readLedger());
      if (json) {
        out.writeln(
          jsonEncode({
            'versionName': current.name,
            'versionCode': current.code,
            'build': current.build,
            'highestIssuedCode': floor,
          }),
        );
      } else if (onlyName) {
        out.writeln(current.name);
      } else if (onlyCode) {
        out.writeln(current.code);
      } else {
        out.writeln('versionName : ${current.name}');
        out.writeln(
          'versionCode : ${current.code}   (highest issued so far: $floor)',
        );
        out.writeln('pubspec     : version: ${current.build}');
      }
      return 0;

    case 'init':
      _expect(positional, 0, 'init');
      final created = manager.initLedger();
      final current = manager.readVersion();
      out.writeln(
        created
            ? 'created tool/release_state.json (highest issued code = ${current.code}, taken from pubspec.yaml)'
            : 'tool/release_state.json already exists. Nothing changed.',
      );
      return 0;

    case 'check':
      _expect(positional, 0, 'check');
      final problems = manager.check();
      if (problems.isEmpty) {
        final current = manager.readVersion();
        out.writeln(
          'ok: ${current.build} (highest issued ${manager.effectiveFloor(current, manager.readLedger())})',
        );
        return 0;
      }
      for (final p in problems) {
        out.writeln('problem: $p');
      }
      return exitConflict;

    case 'next':
      _expect(positional, 0, 'next');
      if (codeOption != null) {
        throw VersionError(
          'next does not take --code. Use "set <name> --code N" or "code N".',
        );
      }
      return _report(
        out,
        await manager.execute(NextOp(releaseId: releaseId), dryRun: dryRun),
        dryRun,
      );

    case 'set':
      _expect(positional, 1, 'set <1.0.N>');
      final name = parseName(positional.single);
      final codeValue = codeOption == null ? null : parseCode(codeOption);
      return _report(
        out,
        await manager.execute(
          SetOp(name, code: codeValue, releaseId: releaseId),
          dryRun: dryRun,
        ),
        dryRun,
      );

    case 'code':
      _expect(positional, 1, 'code <N>');
      return _report(
        out,
        await manager.execute(
          CodeOp(parseCode(positional.single), releaseId: releaseId),
          dryRun: dryRun,
        ),
        dryRun,
      );

    default:
      throw VersionError(
        'Unknown command "$command". See: dart tool/version.dart help',
      );
  }
}

void _expect(List<String> positional, int count, String usage) {
  if (positional.length != count) {
    throw VersionError('Usage: dart tool/version.dart $usage');
  }
}

int _report(IOSink out, Outcome o, bool dryRun) {
  final tag = dryRun ? '[dry-run] ' : '';
  final arrow = o.changed || o.alreadyApplied
      ? '${o.before.name} -> ${o.after.name}'
      : o.before.name;
  out.writeln('$tag${o.operation.label}');
  out.writeln('  versionName : $arrow');
  out.writeln(
    '  versionCode : ${o.before.code} -> ${o.after.code}   (highest issued before: ${o.floorBefore})',
  );
  if (o.note.isNotEmpty) out.writeln('  note        : ${o.note}');
  if (dryRun) {
    if (o.changed) {
      out.writeln('  would modify: pubspec.yaml, tool/release_state.json');
    }
    out.writeln('  nothing was written.');
  } else if (o.written) {
    out.writeln('  updated     : pubspec.yaml, tool/release_state.json');
    out.writeln(
      '  next step   : build the release (see tool/README.md). Nothing was published or pushed.',
    );
  } else if (!o.alreadyApplied) {
    out.writeln('  nothing to do.');
  }
  return 0;
}
