# Shared helpers for the release scripts (sourced, not executed).

# find_sdk_tool <name> [override]
#   Prints the path of an Android build-tool. Order: explicit override, newest build-tools folder, PATH.
find_sdk_tool() {
  local name="$1" override="${2:-}"
  if [[ -n "$override" ]]; then
    printf '%s\n' "$override"
    return 0
  fi
  # Newest SDK build-tools first (older distro packages such as /usr/bin/zipalign lack newer options), then PATH.
  local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}" found
  found="$(ls -d "$sdk"/build-tools/*/"$name" 2>/dev/null | sort -V | tail -n1 || true)"
  if [[ -n "$found" ]]; then
    printf '%s\n' "$found"
    return 0
  fi
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi
  return 1
}

# sha256_of <file>
sha256_of() {
  sha256sum "$1" | cut -d' ' -f1
}
