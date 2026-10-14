#!/usr/bin/env bash
# Builds a Release and collects it under dist/ with a name taken from the recorded version:
#
#   dist/UFUQ-1.0.8.apk                      universal APK (default, same build as before)
#   dist/UFUQ-1.0.8-arm64-v8a.apk  ...       with --split-per-abi
#   dist/UFUQ-1.0.8.aab                      with --aab (add --apk to get both)
#
# It never changes the version (use tool/version.dart for that), never signs anything itself (Gradle's
# existing signing config does) and never uploads or pushes. The output file is a byte-identical copy of
# what Flutter produced, so the signature stays valid.
#
#   tool/build_release.sh [--apk] [--aab] [--split-per-abi] [--skip-build] [--force] [--out DIR] [-- <flutter args>]
#
# Environment: FLUTTER, DART, AAPT, AAPT2, APKSIGNER, JARSIGNER (tool paths), OUT_DIR.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project="$(dirname "$here")"
# shellcheck source=tool/_android_tools.sh
source "$here/_android_tools.sh"

# JDK 24+ prints "A restricted method in java.lang.System has been called" for Gradle's native-platform
# library. It is harmless; this tells the Gradle launcher JVM that native access is expected
# (android/gradle.properties does the same for the daemon).
case " ${GRADLE_OPTS:-} " in
  *--enable-native-access*) ;;
  *) export GRADLE_OPTS="${GRADLE_OPTS:-} --enable-native-access=ALL-UNNAMED" ;;
esac

flutter_bin="${FLUTTER:-flutter}"
dart_bin="${DART:-dart}"
out_dir="${OUT_DIR:-$project/dist}"
want_apk=false
want_aab=false
split=false
skip_build=false
force=false
extra=()

usage() {
  sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apk) want_apk=true ;;
    --aab) want_aab=true ;;
    --split-per-abi) split=true; want_apk=true ;;
    --skip-build) skip_build=true ;;
    --force) force=true ;;
    --out) shift; out_dir="${1:?--out needs a directory}" ;;
    -h|--help) usage; exit 0 ;;
    --) shift; extra=("$@"); break ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done
if ! $want_apk && ! $want_aab; then want_apk=true; fi

fail() { echo "error: $*" >&2; exit "${2:-2}"; }

# apksigner on JDK 24+ prints the same harmless "restricted method" JVM warning on stderr (its launcher script
# takes no JVM options). Drop only those lines; its exit status and every other message are kept.
verify_apk_signature() {
  "$apksigner" verify "$1" 2> >(grep -v -e '^WARNING:' -e '^$' >&2)
}

cd "$project"

# --- the version comes from the version system, read-only
"$dart_bin" "$here/version.dart" check >/dev/null || fail "tool/version.dart check failed. Fix the version first."
name="$("$dart_bin" "$here/version.dart" show --name --project "$project")"
code="$("$dart_bin" "$here/version.dart" show --build-number --project "$project")"
[[ "$name" =~ ^1\.0\.[0-9]+$ ]] || fail "unexpected versionName '$name'" 1
echo "== UFUQ $name (versionCode $code)"

# --- tools
apksigner="$(find_sdk_tool apksigner "${APKSIGNER:-}" || true)"
[[ -n "$apksigner" ]] || fail "apksigner not found. Set APKSIGNER or ANDROID_HOME." 1
jarsigner=""
if $want_aab; then
  jarsigner="$(find_sdk_tool jarsigner "${JARSIGNER:-}" || true)"
  [[ -n "$jarsigner" ]] || fail "jarsigner not found (needed to check the .aab). Set JARSIGNER." 1
fi

# --- build (Flutter does the signing through android/app/build.gradle.kts, unchanged)
if ! $skip_build; then
  if $want_apk; then
    args=(build apk --release)
    $split && args+=(--split-per-abi)
    echo "== $flutter_bin ${args[*]} ${extra[*]:-}"
    "$flutter_bin" "${args[@]}" ${extra[@]+"${extra[@]}"}
  fi
  if $want_aab; then
    echo "== $flutter_bin build appbundle --release ${extra[*]:-}"
    log="$(mktemp)"
    set +e
    "$flutter_bin" build appbundle --release ${extra[@]+"${extra[@]}"} 2>&1 | tee "$log"
    rc="${PIPESTATUS[0]}"
    set -e
    if [[ "$rc" -ne 0 ]]; then
      # Flutter checks the finished bundle with apkanalyzer (Android SDK "cmdline-tools"). Without that
      # package it reports a strip failure even though the bundle is fine. Do the same check ourselves.
      bundle="build/app/outputs/bundle/release/app-release.aab"
      listing=""
      [[ -f "$bundle" ]] && listing="$(unzip -l "$bundle")"
      if grep -q "failed to strip debug symbols" "$log" &&
        grep -q "libflutter.so.sym" <<<"$listing" && grep -q "libapp.so.sym" <<<"$listing"; then
        echo "== note: Flutter could not run its post-build symbol check (Android SDK cmdline-tools / apkanalyzer"
        echo "   is not installed). The bundle contains the stripped native libraries and their symbol files, so it"
        echo "   is accepted. Install cmdline-tools to silence this."
      else
        rm -f "$log"
        fail "flutter build appbundle failed (exit $rc)"
      fi
    fi
    rm -f "$log"
  fi
fi

# --- what to collect: "source|destination name|expected versionCode"
apk_dir="build/app/outputs/flutter-apk"
items=()
if $want_apk; then
  if $split; then
    # Flutter adds 1000 * ABI index to the versionCode of split APKs.
    items+=("$apk_dir/app-armeabi-v7a-release.apk|UFUQ-$name-armeabi-v7a.apk|$((code + 1000))")
    items+=("$apk_dir/app-arm64-v8a-release.apk|UFUQ-$name-arm64-v8a.apk|$((code + 2000))")
    items+=("$apk_dir/app-x86_64-release.apk|UFUQ-$name-x86_64.apk|$((code + 4000))")
  else
    items+=("$apk_dir/app-release.apk|UFUQ-$name.apk|$code")
  fi
fi
if $want_aab; then
  items+=("build/app/outputs/bundle/release/app-release.aab|UFUQ-$name.aab|$code")
fi

# --- verify every source first; nothing is copied unless all of them pass
for item in "${items[@]}"; do
  IFS='|' read -r src dst want_code <<<"$item"
  [[ -f "$src" ]] || fail "expected build output not found: $src"
  echo "== checking $src"
  "$here/verify_apk_version.sh" "$src" "$name" "$want_code" | sed 's/^/   /'
  if [[ "$src" == *.aab ]]; then
    "$jarsigner" -verify "$src" >/dev/null || fail "$src: signature check failed"
    echo "   signature     : ok (jarsigner)"
  else
    verify_apk_signature "$src" || fail "$src: signature check failed"
    echo "   signature     : ok (apksigner)"
  fi
  if [[ -e "$out_dir/$dst" ]] && ! $force; then
    [[ "$(sha256_of "$out_dir/$dst")" == "$(sha256_of "$src")" ]] ||
      fail "$out_dir/$dst already exists with different content (an earlier release with the same name). Use --force to replace it."
  fi
done

# --- collect: byte-identical copies, then verify the copies themselves
mkdir -p "$out_dir"
collected=()
for item in "${items[@]}"; do
  IFS='|' read -r src dst want_code <<<"$item"
  tmp="$out_dir/.$dst.tmp-$$"
  cp -- "$src" "$tmp"
  mv -f -- "$tmp" "$out_dir/$dst"
  [[ "$(sha256_of "$out_dir/$dst")" == "$(sha256_of "$src")" ]] || fail "copy of $src differs from the original"
  if [[ "$dst" == *.aab ]]; then
    "$jarsigner" -verify "$out_dir/$dst" >/dev/null || fail "$dst: signature check failed after the copy"
  else
    verify_apk_signature "$out_dir/$dst" || fail "$dst: signature check failed after the copy"
  fi
  (cd "$out_dir" && sha256sum "$dst" >"$dst.sha256")
  collected+=("$out_dir/$dst")
done

echo "== done. Nothing was uploaded, tagged or pushed."
for f in "${collected[@]}"; do
  printf '   %s  (%s bytes)\n' "$f" "$(stat -c %s "$f")"
done
