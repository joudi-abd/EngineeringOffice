# Release versioning and file names

The app is a Flutter project, so Flutter's own versioning is the system: `pubspec.yaml` →
`version: 1.0.<n>+<code>` feeds Android (`versionName` / `versionCode` through `flutter.versionName` /
`flutter.versionCode` in `android/app/build.gradle.kts`) and iOS. Nothing parallel was added: `tool/version.dart`
only edits that one line, safely.

| Part | Meaning | Who changes it |
|------|---------|----------------|
| `1.0.<n>` — **versionName** | What users see | `next` (+1) or `set` (by hand, may go down) |
| `<code>` — **versionCode** | What Android compares to decide "is this an update" | Always **only goes up**, never reused |

Single source of truth: the `version:` line of `pubspec.yaml`.
Guard: `tool/release_state.json` (commit it) remembers the **highest versionCode ever issued**, the last release and a short
history, so a hand edit, a reset of the visible name or a re-run can never lower or repeat a code.

## Commands

Run from `mobile/`:

```bash
dart tool/version.dart show                    # 1.0.0 / 1   (also: --json | --name | --build-number)
dart tool/version.dart next                    # 1.0.4+10  ->  1.0.5+11
dart tool/version.dart set 1.0.8               # choose the visible name (can be lower). Code still goes up
dart tool/version.dart set 1.0.8 --code 140    # also choose the code (must be above every issued one)
dart tool/version.dart code 140                # raise only the code
dart tool/version.dart dry-run next            # preview, writes NOTHING (also: dry-run set 1.0.8, --dry-run, -n)
dart tool/version.dart check                   # pubspec and ledger agree, code never went down (exit 2 if not)
dart tool/version.dart init                    # create release_state.json from pubspec.yaml if missing (done)
tool/verify_apk_version.sh dist/UFUQ-1.0.8.apk   # reads the real metadata of an APK / AAB
tool/build_release.sh                          # release build, named dist/UFUQ-<versionName>.apk (see below)
```

Plain `flutter run` / `flutter build apk --debug` never touch the version. Only `next`, `set`, `code` do.

Example, resetting the visible name:

```
1.0.12+20  -- set 1.0.8 -->  1.0.8+21     # name goes back, code still climbs
```

### Rules

- Name: exactly `1.0.<n>` (`n` ≥ 0, no leading zeros). Anything else (`1.0`, `1.1.0`, `1.0.x`, `1.0.4-beta`, `v1.0.4`) is rejected.
- Code: integer from 1 to 2099990000 (Android's limit is 2100000000; per-ABI splits add up to 4000 — see below).
- `next` and `set` always issue `highest-issued + 1` as the code unless you pass an explicit `--code`, which must be above it.
- The store's real highest code is unknown to the script. If the store ever holds more than the ledger, run
  `dart tool/version.dart code <that number>` once; every later release continues above it.
- A pubspec whose code is below the ledger (someone edited it down) is refused with exit code 2.
- Exit codes: `0` ok · `1` bad input · `2` conflict (lowered code, corrupt ledger, lock timeout).
- Files are written atomically (temp file + rename), ledger first and pubspec second. If a run dies in between, repeat
  the same command with the same `--release-id` and it completes the interrupted step **without** issuing a new version.
- An exclusive lock (`tool/.version.lock`) serialises concurrent runs on one checkout (waits up to 30 s).
- `dry-run` reads only: it takes no lock and creates/changes no file.

### Re-running a failed release

Pass an id that identifies the release attempt, not the retry:

```bash
dart tool/version.dart next --release-id "$GITHUB_RUN_ID"      # or env UFUQ_RELEASE_ID
```

The same id again → "already applied", no second bump. A new id → a new version.

## Building a release with the right file names

```bash
dart tool/version.dart dry-run next                         # 1. preview (optional)
dart tool/version.dart next --release-id "release-$(date +%Y%m%d-%H%M)"   # 2. choose the version (the only step that bumps)
tool/build_release.sh                                       # 3. build + verify + collect
```

| Command | Result in `dist/` |
|---------|-------------------|
| `tool/build_release.sh` | `UFUQ-1.0.8.apk` (universal APK: arm64-v8a, armeabi-v7a, x86_64 — the build the project always produced) |
| `tool/build_release.sh --aab` | `UFUQ-1.0.8.aab` only (Google Play bundle) |
| `tool/build_release.sh --apk --aab` | both `UFUQ-1.0.8.apk` and `UFUQ-1.0.8.aab` |
| `tool/build_release.sh --split-per-abi` | `UFUQ-1.0.8-armeabi-v7a.apk`, `UFUQ-1.0.8-arm64-v8a.apk`, `UFUQ-1.0.8-x86_64.apk` |
| `tool/build_release.sh --skip-build` | only verifies and collects what `flutter build` already produced |
| `tool/build_release.sh --force` | replace an existing `dist/` file of the same name that has different content |
| `tool/build_release.sh --out DIR` | collect somewhere else |
| `tool/build_release.sh -- --obfuscate --split-debug-info=...` | everything after `--` goes to `flutter build` |

Each artifact also gets `<name>.sha256` next to it. `dist/` is git-ignored.

What the script does, in order:

1. `version.dart check`, then reads `versionName` / `versionCode` (read-only: it never bumps — only `next` / `set` / `code` do, so
   debug builds and accidental builds can't change the version).
2. Runs the normal `flutter build apk --release` (and/or `appbundle`). Signing is exactly what `android/app/build.gradle.kts` already does.
3. Reads the version **inside** each file (aapt for APKs, `tool/aab_manifest.py` for bundles) and compares it with the recorded
   one, including `applicationId = com.ufuq.imperium`. Split APKs are expected at `versionCode + 1000` (armeabi-v7a), `+ 2000` (arm64-v8a), `+ 4000` (x86_64), which is what Flutter adds.
4. Checks the signature (`apksigner verify` for APKs, `jarsigner -verify` for the bundle).
5. Only if everything passed: copies the file byte for byte to `dist/UFUQ-<name>…`, checks the SHA-256 matches and verifies the
   signature of the copy again. A rename/copy never touches the file contents, and the APK signature covers contents, not the file name.
6. Refuses to replace an existing `dist/UFUQ-<name>…` with different content (a reset name like 1.0.12 → 1.0.8 can repeat an earlier name) unless `--force`.

Not done by the script: committing, tagging, pushing, uploading. Keep `pubspec.yaml` and `tool/release_state.json` committed yourself.

Notes:

- Flutter's `flutter build appbundle` runs a final symbol check through the Android SDK **cmdline-tools** (`apkanalyzer`). On a machine without
  that package it prints "failed to strip debug symbols" and exits 1 even though the bundle is fine. `build_release.sh` repeats the check itself
  (the stripped libraries and `.sym` files must be inside the bundle) and continues with a note; any other failure still stops the build.
  Installing cmdline-tools removes the note.
- Don't publish the universal APK and the split APKs side by side to the same audience: their versionCodes differ by design.

## Android compatibility check

```bash
tool/check_apk_compat.sh dist/UFUQ-1.0.8.apk
```

Read-only report: applicationId, version, minSdk / targetSdk / compileSdk, ABIs, permissions, features, signature schemes and
certificate, 16 KB zip alignment and the ELF alignment of every native library. It fails (exit 2) on an invalid signature, a missing
arm64-v8a build, a 64-bit library that is not 16 KB aligned or a zip that is not 16 KB aligned, and warns when the APK is signed with
the Android **debug** certificate (fine for direct installs, rejected by Google Play, and different on every machine).

## CI/CD

There is no CI in the repository today, so no workflow file was added. When one is created, the release job should:

```yaml
concurrency:                      # one release at a time per branch
  group: release-${{ github.ref }}
  cancel-in-progress: false
steps:
  - uses: actions/checkout@v4
  - run: dart tool/version.dart check
  - run: dart tool/version.dart next --release-id "${{ github.run_id }}"   # run_id is the same on "Re-run jobs"
  - run: tool/build_release.sh --apk --aab   # builds, verifies version + signature, writes dist/UFUQ-<version>.apk/.aab
  - uses: actions/upload-artifact@v4
    with:
      name: UFUQ-release
      path: mobile/dist/UFUQ-*            # the new names, not build/app/outputs/.../app-release.*
  # then commit pubspec.yaml + tool/release_state.json yourself (or with an explicit, reviewed step)
```

Two jobs on different checkouts cannot share the file lock; the `concurrency` group (or pushing the bumped files
before the next release starts) covers that, and a stale checkout is caught by the ledger: its code would be below
the committed floor.

## Things to know

- `--split-per-abi` makes Flutter add 1000–4000 to the versionCode. `build_release.sh` accounts for that; when calling
  `verify_apk_version.sh` by hand on such an APK, pass the expected name and code explicitly.
- The release build type in `android/app/build.gradle.kts` is currently signed with the **debug key**. This tool does not
  touch signing, the application id (`com.ufuq.imperium`) or user data; replace the debug key with a real upload key
  before any store release.
- Always build with `flutter build ...`, not a bare `./gradlew`: Flutter refreshes `android/local.properties` (where Gradle
  reads the version) from `pubspec.yaml` only when it builds. `verify_apk_version.sh` exists to catch exactly that kind of stale value.
- Run the tests: `flutter test test/tool`.
