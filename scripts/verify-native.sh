#!/usr/bin/env bash
# Builds and tests the native LeafLoom projects on a Mac with Xcode.
#
#   ./scripts/verify-native.sh            # iOS app + visionOS prototype
#   ./scripts/verify-native.sh ios        # iOS only
#   ./scripts/verify-native.sh visionos   # visionOS only
#
# Optional environment variables:
#   IOS_SIMULATOR="iPhone 16"             simulator name (default: first available iPhone)
#   VISION_SIMULATOR="Apple Vision Pro"   simulator name (default: first available Vision Pro)
#
# Logs and .xcresult bundles go to verification-logs/<timestamp>/. Copy the summary it prints into
# docs/TEST_PLAN.md; do not record results you did not run.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-all}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/verification-logs/$STAMP"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Install Xcode 16 or later and run: sudo xcode-select -s /Applications/Xcode.app" >&2
  exit 2
fi
mkdir -p "$OUT"

echo "Xcode: $(xcodebuild -version | tr '\n' ' ')"
echo "Logs:  $OUT"
echo

first_simulator() {
  # Prints the name of the first available simulator whose name starts with $1.
  xcrun simctl list devices available | sed -n "s/^ *\($1[^(]*\) (.*/\1/p" | sed 's/ *$//' | head -n 1
}

declare -a SUMMARY=()

run_step() {
  # run_step <label> <log-name> <command...>
  local label="$1" log="$2"
  shift 2
  echo "▶ $label"
  if "$@" >"$OUT/$log.log" 2>&1; then
    echo "  ✓ passed"
    SUMMARY+=("PASS  $label")
  else
    echo "  ✗ failed — see $OUT/$log.log"
    grep -E "error:|failed|Failing tests:" "$OUT/$log.log" | head -n 20 | sed 's/^/    /'
    SUMMARY+=("FAIL  $label  ($log.log)")
  fi
  local executed
  executed="$(grep -E "Executed [0-9]+ tests?" "$OUT/$log.log" | tail -n 1)"
  [ -n "$executed" ] && echo "  $executed" && SUMMARY+=("      $executed")
  echo
}

verify_ios() {
  local sim="${IOS_SIMULATOR:-$(first_simulator iPhone)}"
  if [ -z "$sim" ]; then
    echo "No iPhone simulator found. Install one in Xcode → Settings → Components." >&2
    SUMMARY+=("SKIP  iOS (no iPhone simulator)")
    return
  fi
  local dest="platform=iOS Simulator,name=$sim"
  echo "iOS simulator: $sim"
  cd "$ROOT/native-ios" || return
  run_step "iOS build (LeafLoom)" ios-build \
    xcodebuild -project LeafLoom.xcodeproj -scheme LeafLoom -destination "$dest" build
  run_step "iOS unit + UI tests" ios-test \
    xcodebuild -project LeafLoom.xcodeproj -scheme LeafLoom -destination "$dest" \
      -resultBundlePath "$OUT/ios-tests.xcresult" test
}

verify_visionos() {
  if ! xcodebuild -showsdks 2>/dev/null | grep -q xros; then
    echo "visionOS SDK not installed. Add it in Xcode → Settings → Components." >&2
    SUMMARY+=("SKIP  visionOS (SDK not installed)")
    return
  fi
  local sim="${VISION_SIMULATOR:-$(first_simulator "Apple Vision Pro")}"
  if [ -z "$sim" ]; then
    echo "No Apple Vision Pro simulator found." >&2
    SUMMARY+=("SKIP  visionOS (no simulator)")
    return
  fi
  local dest="platform=visionOS Simulator,name=$sim"
  echo "visionOS simulator: $sim"
  cd "$ROOT/partB-visionos" || return
  run_step "visionOS build (LeafLoomSpatial)" visionos-build \
    xcodebuild -project LeafLoomSpatial.xcodeproj -scheme LeafLoomSpatial -destination "$dest" build
  run_step "visionOS unit tests" visionos-test \
    xcodebuild -project LeafLoomSpatial.xcodeproj -scheme LeafLoomSpatial -destination "$dest" \
      -resultBundlePath "$OUT/visionos-tests.xcresult" test
}

case "$TARGET" in
  ios) verify_ios ;;
  visionos) verify_visionos ;;
  all) verify_ios; verify_visionos ;;
  *) echo "Usage: $0 [all|ios|visionos]" >&2; exit 2 ;;
esac

echo "──────── Summary ($STAMP) ────────"
printf '%s\n' "${SUMMARY[@]}" | tee "$OUT/summary.txt"

printf '%s\n' "${SUMMARY[@]}" | grep -q '^FAIL' && exit 1
exit 0
