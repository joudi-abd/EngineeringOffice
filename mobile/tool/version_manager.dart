// Release version management for the UFUQ mobile app.
//
// Single source of truth: the `version:` line of pubspec.yaml (`1.0.<patch>+<code>`).
// Flutter feeds it to Android (versionName / versionCode) and iOS (CFBundleShortVersionString /
// CFBundleVersion), so no Gradle or Xcode file needs to know about it.
//
// Next to it, tool/release_state.json is a small *guard ledger*, not a second version:
//   * code_floor      highest versionCode ever issued or declared. It only ever goes up, so
//                     resetting the visible name (1.0.12 -> 1.0.8) can never lower the code.
//   * last_release    the id of the last release run + the version it produced, so re-running a
//                     failed release job is a no-op instead of another bump.
//
// Plain dart:core + dart:io on purpose: it runs with `dart tool/version.dart` anywhere Flutter is.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// The visible version series. `1.0.x`: only the last part moves.
const versionSeries = '1.0';

/// Android's hard limit is 2100000000; Flutter adds up to 4000 on top for split-per-abi builds.
const maxVersionCode = 2099990000;

/// Exit codes of the CLI.
const exitUsage = 1;
const exitConflict = 2;

class VersionError implements Exception {
  VersionError(this.message, {this.exitCode = exitUsage});
  final String message;
  final int exitCode;
  @override
  String toString() => message;
}

class AppVersion {
  const AppVersion(this.name, this.code);
  final String name;
  final int code;

  String get build => '$name+$code';
  int get patch => int.parse(name.split('.').last);

  @override
  bool operator ==(Object other) =>
      other is AppVersion && other.name == name && other.code == code;
  @override
  int get hashCode => Object.hash(name, code);
  @override
  String toString() => build;
}

final _nameRe = RegExp(
  '^${RegExp.escape(versionSeries)}\\.(0|[1-9][0-9]{0,8})\$',
);
final _codeRe = RegExp(r'^[1-9][0-9]*$');

/// `1.0.<patch>` only: no leading zeros, no spaces, no suffixes.
String parseName(String raw) {
  if (!_nameRe.hasMatch(raw)) {
    throw VersionError(
      'Invalid version name "$raw". Expected $versionSeries.<number> '
      '(for example $versionSeries.9), without leading zeros or extra characters.',
    );
  }
  return raw;
}

/// A positive integer within Android's limits.
int parseCode(String raw, {String what = 'versionCode'}) {
  if (!_codeRe.hasMatch(raw) || raw.length > 10) {
    throw VersionError(
      'Invalid $what "$raw". Expected a positive whole number.',
    );
  }
  final value = int.parse(raw);
  if (value > maxVersionCode) {
    throw VersionError(
      '$what $value is above the supported maximum $maxVersionCode.',
    );
  }
  return value;
}

// ------------------------------------------------------------------------------ operations

sealed class Operation {
  const Operation({this.releaseId});

  /// Identifies one release run (for example the CI run id). The same id never bumps twice.
  final String? releaseId;
  String get label;
}

/// versionName patch + 1, versionCode = highest issued + 1.
class NextOp extends Operation {
  const NextOp({super.releaseId});
  @override
  String get label => 'next';
}

/// versionName to a chosen value. versionCode still goes up (or to [code] if it is higher).
class SetOp extends Operation {
  const SetOp(this.name, {this.code, super.releaseId});
  final String name;
  final int? code;
  @override
  String get label => 'set';
}

/// Raise only the versionCode (for example when the store already holds a higher one).
class CodeOp extends Operation {
  const CodeOp(this.code, {super.releaseId});
  final int code;
  @override
  String get label => 'code';
}

// ------------------------------------------------------------------------------ ledger

class LastRelease {
  const LastRelease({this.id, required this.version, required this.at});
  final String? id;
  final AppVersion version;
  final String at;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': version.name,
    'code': version.code,
    'at': at,
  };
}

class Ledger {
  const Ledger({
    required this.codeFloor,
    this.lastRelease,
    this.history = const [],
  });

  final int codeFloor;
  final LastRelease? lastRelease;
  final List<Map<String, Object?>> history;

  static const historyLimit = 100;

  Map<String, Object?> toJson() => {
    'schema': 1,
    'series': versionSeries,
    'code_floor': codeFloor,
    'last_release': lastRelease?.toJson(),
    'history': history,
  };
}

// ------------------------------------------------------------------------------ outcome

class Outcome {
  const Outcome({
    required this.operation,
    required this.before,
    required this.after,
    required this.floorBefore,
    required this.note,
    this.changed = false,
    this.alreadyApplied = false,
    this.repaired = false,
    this.written = false,
  });

  final Operation operation;
  final AppVersion before;
  final AppVersion after;
  final int floorBefore;

  /// Whether the version differs from what is on disk now.
  final bool changed;

  /// This release id was already applied, nothing was bumped again.
  final bool alreadyApplied;

  /// The ledger was ahead of pubspec (an interrupted run); pubspec was completed, no new bump.
  final bool repaired;

  /// Files were really written (false for dry runs and no-ops).
  final bool written;
  final String note;
}

// ------------------------------------------------------------------------------ manager

class VersionManager {
  VersionManager(this.project, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// The Flutter project folder (the one holding pubspec.yaml).
  final Directory project;
  final DateTime Function() _clock;

  File get pubspecFile => File('${project.path}/pubspec.yaml');
  File get stateFile => File('${project.path}/tool/release_state.json');
  File get _lockFile => File('${project.path}/tool/.version.lock');

  static final _versionLine = RegExp(
    r'^version:[ \t]*([^\s#]+)[ \t]*(#.*)?$',
    multiLine: true,
  );

  // ---- reading

  AppVersion readVersion() {
    if (!pubspecFile.existsSync()) {
      throw VersionError('pubspec.yaml not found in ${project.path}');
    }
    final text = pubspecFile.readAsStringSync();
    final matches = _versionLine.allMatches(text).toList();
    if (matches.length != 1) {
      throw VersionError(
        'Expected exactly one top-level "version:" line in pubspec.yaml, found ${matches.length}.',
      );
    }
    final value = matches.single.group(1)!;
    final parts = value.split('+');
    if (parts.length != 2) {
      throw VersionError(
        'pubspec.yaml version "$value" must look like $versionSeries.<n>+<code>.',
      );
    }
    return AppVersion(parseName(parts[0]), parseCode(parts[1]));
  }

  /// Null when no ledger exists yet (first run).
  Ledger? readLedger() {
    if (!stateFile.existsSync()) return null;
    try {
      final json =
          jsonDecode(stateFile.readAsStringSync()) as Map<String, dynamic>;
      final floor = json['code_floor'];
      if (floor is! int || floor < 1) throw const FormatException('code_floor');
      LastRelease? last;
      final raw = json['last_release'];
      if (raw is Map<String, dynamic>) {
        last = LastRelease(
          id: raw['id'] as String?,
          version: AppVersion(
            parseName(raw['name'] as String),
            raw['code'] as int,
          ),
          at: raw['at'] as String? ?? '',
        );
      }
      return Ledger(
        codeFloor: floor,
        lastRelease: last,
        history: [
          for (final item in (json['history'] as List<dynamic>? ?? const []))
            Map<String, Object?>.from(item as Map),
        ],
      );
    } on VersionError {
      rethrow;
    } catch (_) {
      throw VersionError(
        'tool/release_state.json is unreadable. Restore it from git; do not guess the code floor.',
        exitCode: exitConflict,
      );
    }
  }

  /// Highest versionCode issued so far: the ledger floor, or pubspec if that is higher.
  int effectiveFloor(AppVersion current, Ledger? ledger) =>
      math.max(ledger?.codeFloor ?? 0, current.code);

  /// Everything wrong with the current files (empty = healthy).
  List<String> check() {
    final problems = <String>[];
    final AppVersion current;
    try {
      current = readVersion();
    } on VersionError catch (e) {
      return [e.message];
    }
    final Ledger? ledger;
    try {
      ledger = readLedger();
    } on VersionError catch (e) {
      return [e.message];
    }
    if (ledger == null) {
      problems.add(
        'tool/release_state.json is missing (it is created by the first next/set).',
      );
    } else {
      if (current.code < ledger.codeFloor) {
        problems.add(
          'versionCode ${current.code} is lower than the highest issued ${ledger.codeFloor}. '
          'It must never go down; restore pubspec.yaml or run "code <n>".',
        );
      }
      final last = ledger.lastRelease;
      if (last != null && current.code < last.version.code) {
        problems.add(
          'pubspec.yaml (${current.build}) is behind the last recorded release (${last.version.build}). '
          'Re-run that release with the same --release-id to finish it.',
        );
      }
    }
    return problems;
  }

  /// Seeds the ledger from pubspec.yaml when it does not exist. Returns whether it was created.
  bool initLedger() {
    final current = readVersion();
    if (stateFile.existsSync()) {
      readLedger(); // refuse to treat a corrupt file as "fine"
      return false;
    }
    stateFile.parent.createSync(recursive: true);
    _writeLedger(
      Ledger(
        codeFloor: current.code,
        lastRelease: null,
        history: [
          {
            'at': _clock().toUtc().toIso8601String(),
            'op': 'init',
            'from': current.build,
            'to': current.build,
            'release_id': null,
          },
        ],
      ),
    );
    return true;
  }

  // ---- running

  /// Applies [op]. A dry run reads only: no lock, no ledger, no pubspec write.
  Future<Outcome> execute(Operation op, {bool dryRun = false}) async {
    if (dryRun) return _run(op, write: false);
    stateFile.parent.createSync(recursive: true);
    final handle = await _lockFile.open(mode: FileMode.append);
    try {
      await _acquire(handle);
      return _run(op, write: true);
    } finally {
      try {
        await handle.unlock();
      } catch (_) {}
      await handle.close();
    }
  }

  /// Waits (polling, up to 30 s) for the exclusive lock; another release is running meanwhile.
  Future<void> _acquire(RandomAccessFile handle) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (true) {
      try {
        await handle.lock(FileLock.exclusive);
        return;
      } on FileSystemException {
        if (DateTime.now().isAfter(deadline)) {
          throw VersionError(
            'Another version operation is holding the lock. Try again.',
            exitCode: exitConflict,
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    }
  }

  Outcome _run(Operation op, {required bool write}) {
    final current = readVersion();
    final ledger = readLedger();
    final floor = effectiveFloor(current, ledger);

    // Same release id again (a re-run of a failed job): never bump twice.
    final last = ledger?.lastRelease;
    if (op.releaseId != null && last != null && last.id == op.releaseId) {
      final recorded = last.version;
      if (current == recorded) {
        return Outcome(
          operation: op,
          before: current,
          after: current,
          floorBefore: floor,
          alreadyApplied: true,
          note:
              'Release id "${op.releaseId}" was already applied. Nothing changed.',
        );
      }
      if (current.code < recorded.code) {
        if (write) _writePubspec(recorded);
        return Outcome(
          operation: op,
          before: current,
          after: recorded,
          floorBefore: floor,
          alreadyApplied: true,
          repaired: true,
          changed: true,
          written: write,
          note:
              'Release id "${op.releaseId}" was recorded but pubspec.yaml lagged '
              '(interrupted run). Completed it; no new version was issued.',
        );
      }
      return Outcome(
        operation: op,
        before: current,
        after: current,
        floorBefore: floor,
        alreadyApplied: true,
        note:
            'Release id "${op.releaseId}" was already applied (${recorded.build}); '
            'the project has moved on to ${current.build}. Nothing changed.',
      );
    }

    if (ledger != null && current.code < ledger.codeFloor) {
      throw VersionError(
        'versionCode ${current.code} in pubspec.yaml is lower than the highest issued '
        '(${ledger.codeFloor}). Refusing to continue: a lower code cannot be installed as an update.',
        exitCode: exitConflict,
      );
    }

    final AppVersion next;
    String note = '';
    switch (op) {
      case NextOp():
        next = AppVersion(
          '$versionSeries.${current.patch + 1}',
          _nextCode(floor),
        );
      case SetOp(:final name, :final code):
        parseName(name);
        if (code != null) _requireAboveFloor(code, floor);
        if (name == current.name && code == null) {
          return Outcome(
            operation: op,
            before: current,
            after: current,
            floorBefore: floor,
            note:
                'Version name is already $name. Nothing changed '
                '(use --code to raise the code on its own).',
          );
        }
        next = AppVersion(name, code ?? _nextCode(floor));
      case CodeOp(:final code):
        _requireAboveFloor(code, floor);
        next = AppVersion(current.name, code);
    }
    if (next.code <= floor) {
      throw VersionError(
        'Internal check failed: versionCode would not increase.',
        exitCode: exitConflict,
      );
    }

    if (write) {
      final now = _clock().toUtc().toIso8601String();
      final history = [
        ...?ledger?.history,
        {
          'at': now,
          'op': op.label,
          'from': current.build,
          'to': next.build,
          'release_id': op.releaseId,
        },
      ];
      final trimmed = history.length > Ledger.historyLimit
          ? history.sublist(history.length - Ledger.historyLimit)
          : history;
      // Ledger first, pubspec second: if we die in between, the ledger already holds the new
      // code, so a retry with the same release id completes pubspec instead of bumping again.
      _writeLedger(
        Ledger(
          codeFloor: next.code,
          lastRelease: LastRelease(id: op.releaseId, version: next, at: now),
          history: trimmed,
        ),
      );
      _writePubspec(next);
    }
    return Outcome(
      operation: op,
      before: current,
      after: next,
      floorBefore: floor,
      changed: true,
      written: write,
      note: note,
    );
  }

  int _nextCode(int floor) {
    final code = floor + 1;
    if (code > maxVersionCode) {
      throw VersionError(
        'versionCode would exceed the supported maximum $maxVersionCode.',
      );
    }
    return code;
  }

  void _requireAboveFloor(int code, int floor) {
    if (code > maxVersionCode) {
      throw VersionError(
        'versionCode $code is above the supported maximum $maxVersionCode.',
      );
    }
    if (code <= floor) {
      throw VersionError(
        'versionCode $code is not above the highest issued ($floor). '
        'A lower or repeated code cannot be installed as an update.',
        exitCode: exitConflict,
      );
    }
  }

  // ---- writing (atomic: temp file in the same folder, then rename)

  void _writePubspec(AppVersion version) {
    final text = pubspecFile.readAsStringSync();
    final replaced = text.replaceFirstMapped(_versionLine, (m) {
      final comment = m.group(2);
      return 'version: ${version.build}${comment == null ? '' : ' $comment'}';
    });
    _atomicWrite(pubspecFile, replaced);
  }

  void _writeLedger(Ledger ledger) {
    const encoder = JsonEncoder.withIndent('  ');
    _atomicWrite(stateFile, '${encoder.convert(ledger.toJson())}\n');
  }

  void _atomicWrite(File target, String content) {
    final temp = File('${target.path}.tmp-$pid');
    temp.writeAsStringSync(content, flush: true);
    temp.renameSync(target.path);
  }
}
