#!/usr/bin/env bash
# Read-only Android compatibility report for a built APK (nothing is installed, signed or modified).
#
#   tool/check_apk_compat.sh dist/UFUQ-1.0.8.apk
#
# Hard failures (exit 2): signature does not verify, no arm64-v8a build, a native library whose ELF segments are
# not 16 KB aligned (Android 15+ 16 KB page-size devices), APK not 16 KB zip-aligned.
# Warnings (exit 0): signed with the Android *debug* certificate (fine for direct installs, rejected by Google Play).
#
# Environment: AAPT, APKSIGNER, ZIPALIGN (tool paths).
set -euo pipefail

apk="${1:-}"
[[ -n "$apk" && -f "$apk" ]] || { echo "usage: $0 <apk>" >&2; exit 1; }
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tool/_android_tools.sh
source "$here/_android_tools.sh"

aapt="$(find_sdk_tool aapt "${AAPT:-}" || true)"
apksigner="$(find_sdk_tool apksigner "${APKSIGNER:-}" || true)"
zipalign="$(find_sdk_tool zipalign "${ZIPALIGN:-}" || true)"
for t in aapt apksigner zipalign readelf unzip; do
  v="${!t:-}"
  [[ -n "$v" ]] || command -v "$t" >/dev/null 2>&1 || { echo "error: $t not found" >&2; exit 1; }
done

fail=0
warn=0
bad() { echo "  FAIL  $*"; fail=1; }
note() { echo "  WARN  $*"; warn=1; }
ok() { echo "  ok    $*"; }

badging="$("$aapt" dump badging "$apk")"
first="$(sed -n '1p' <<<"$badging")"
field() { sed -n "s/.*$1='\([^']*\)'.*/\1/p" <<<"$2" | sed -n '1p'; }

echo "== $apk"
echo "applicationId : $(sed -n "s/^package: name='\([^']*\)'.*/\1/p" <<<"$first")"
echo "versionName   : $(field versionName "$first")"
echo "versionCode   : $(field versionCode "$first")"
echo "minSdk        : $(sed -n "s/^sdkVersion:'\([0-9]*\)'.*/\1/p" <<<"$badging")"
echo "targetSdk     : $(sed -n "s/^targetSdkVersion:'\([0-9]*\)'.*/\1/p" <<<"$badging")"
echo "compileSdk    : $(field compileSdkVersion "$first")"
echo "native ABIs   : $(sed -n "s/^native-code: //p" <<<"$badging")"
echo "permissions   :"
sed -n "s/^uses-permission: name='\(.*\)'.*/  - \1/p" <<<"$badging"
echo "features      :"
{ sed -n "s/^ *uses-feature\(-not-required\)\?: name='\([^']*\)'.*/  - \2/p" <<<"$badging"; } | sort -u

echo "== signature"
sig="$("$apksigner" verify --verbose --print-certs "$apk" 2>&1 || true)"
if grep -q "^Verifies" <<<"$sig"; then ok "apksigner: verifies"; else bad "apksigner: does not verify"; sed 's/^/        /' <<<"$sig" | head -5; fi
grep "^Verified using v[1-4]" <<<"$sig" | sed 's/^/        /'
grep "certificate DN\|SHA-256 digest" <<<"$sig" | sed 's/^/        /'
if grep -q "CN=Android Debug" <<<"$sig"; then
  note "signed with the Android DEBUG certificate: installs directly, but Google Play rejects it and a build on another machine gets a different debug key (updates between them fail)"
fi

echo "== native libraries / 16 KB page size"
if grep -q "native-code:.*arm64-v8a" <<<"$badging"; then ok "arm64-v8a present (64-bit)"; else bad "no arm64-v8a build"; fi
if "$zipalign" -c -P 16 4 "$apk" >/dev/null 2>&1; then ok "zip is 16 KB aligned (zipalign -P 16)"; else bad "zip is not 16 KB aligned"; fi
tmp="$(mktemp -d)"
trap 'rm -r "$tmp"' EXIT
unzip -q -o "$apk" 'lib/*' -d "$tmp" 2>/dev/null || true
while IFS= read -r so; do
  rel="${so#"$tmp"/}"
  align="$(readelf -lW "$so" | awk '/LOAD/{print $NF}' | sort -u | tr '\n' ' ')"
  worst=$((16#$(tr ' ' '\n' <<<"$align" | sed 's/0x//' | grep . | sort | head -n1)))
  if [[ "$rel" == lib/arm64-v8a/* || "$rel" == lib/x86_64/* ]]; then
    if ((worst >= 16384)); then ok "$rel  align ${align}"; else bad "$rel  align ${align}(< 0x4000)"; fi
  else
    echo "  --    $rel  align ${align}(32-bit ABI, not subject to the 16 KB rule)"
  fi
done < <(find "$tmp/lib" -name '*.so' 2>/dev/null | sort)

echo
if ((fail)); then echo "RESULT: FAIL"; exit 2; fi
if ((warn)); then echo "RESULT: ok with warnings"; else echo "RESULT: ok"; fi
