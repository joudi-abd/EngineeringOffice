#!/usr/bin/env bash
# Reads the version that is really inside a built APK / AAB (its manifest metadata) and compares it with
# pubspec.yaml, so a release can never ship with a different number than the one recorded.
#
#   tool/verify_apk_version.sh build/app/outputs/flutter-apk/app-release.apk
#   tool/verify_apk_version.sh dist/UFUQ-1.0.9.aab                       # .aab works too (needs python3)
#   tool/verify_apk_version.sh app.apk 1.0.9 12      # compare with explicit name / code instead
#
# Environment: AAPT / AAPT2 (tool paths), PYTHON (for .aab), DART (path to dart), APP_ID (default com.ufuq.imperium).
set -euo pipefail

apk="${1:-}"
if [[ -z "$apk" || ! -f "$apk" ]]; then
  echo "usage: $0 <apk> [expected_name expected_code]" >&2
  exit 1
fi

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project="$(dirname "$here")"
dart_bin="${DART:-dart}"
app_id="${APP_ID:-com.ufuq.imperium}"

# --- locate aapt / aapt2
# shellcheck source=tool/_android_tools.sh
source "$here/_android_tools.sh"
is_bundle=false
[[ "$apk" == *.aab ]] && is_bundle=true
aapt=""
if ! $is_bundle; then
  aapt="$(find_sdk_tool aapt "${AAPT:-}" || find_sdk_tool aapt2 "${AAPT2:-}" || true)"
  if [[ -z "$aapt" ]]; then
    echo "error: aapt/aapt2 not found. Set AAPT / AAPT2 or ANDROID_HOME." >&2
    exit 1
  fi
fi

# --- expected
if [[ $# -ge 3 ]]; then
  want_name="$2"
  want_code="$3"
else
  want_name="$("$dart_bin" "$here/version.dart" show --name --project "$project")"
  want_code="$("$dart_bin" "$here/version.dart" show --build-number --project "$project")"
fi

# --- actual, from the manifest inside the file
if $is_bundle; then
  # aapt2 cannot read .aab files; tool/aab_manifest.py reads the protobuf manifest directly.
  meta="$("${PYTHON:-python3}" "$here/aab_manifest.py" "$apk")"
  got_id="$(sed -n 's/^package=//p' <<<"$meta")"
  got_code="$(sed -n 's/^versionCode=//p' <<<"$meta")"
  got_name="$(sed -n 's/^versionName=//p' <<<"$meta")"
else
  badging="$("$aapt" dump badging "$apk" | sed -n '1p')"
  got_id="$(sed -n "s/.*package: name='\([^']*\)'.*/\1/p" <<<"$badging")"
  got_code="$(sed -n "s/.*versionCode='\([^']*\)'.*/\1/p" <<<"$badging")"
  got_name="$(sed -n "s/.*versionName='\([^']*\)'.*/\1/p" <<<"$badging")"
fi

echo "file          : $apk"
echo "applicationId : $got_id"
echo "versionName   : $got_name   (expected $want_name)"
echo "versionCode   : $got_code   (expected $want_code)"

status=0
[[ "$got_id" == "$app_id" ]] || { echo "MISMATCH applicationId (expected $app_id)" >&2; status=2; }
[[ "$got_name" == "$want_name" ]] || { echo "MISMATCH versionName" >&2; status=2; }
[[ "$got_code" == "$want_code" ]] || { echo "MISMATCH versionCode" >&2; status=2; }
[[ $status -eq 0 ]] && echo "ok: the APK carries the recorded version."
exit $status
