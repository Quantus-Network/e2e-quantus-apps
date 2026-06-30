#!/usr/bin/env bash
#
# Run Patrol E2E tests on an iOS Simulator.
#
# iOS counterpart of scripts/patrol_android_emulator.sh for local E2E runs.
# Unlike physical devices, the simulator does not hit the xcodebuild
# "-destination-timeout 1" / "Device is busy" problem, so we can let
# `patrol test` build AND run in one step (see patrol_ios_device.sh if you
# need a real device).
#
# Usage:
#   scripts/patrol_ios_simulator.sh [options] [test_target ...]
#
# Options:
#   -d, --device <udid>       Simulator UDID (default: first booted simulator).
#   -s, --simulator <name>    Boot this simulator when none is running
#                             (e.g. "iPhone 16 Pro").
#       --debug               Build a debug binary (default).
#       --release             Build a release binary.
#
# Environment:
#   IOS_SIMULATOR_DEVICE      Default simulator name to boot when none is
#                             running and -s is not passed.
#   SIMULATOR_BOOT_TIMEOUT    Seconds to wait for boot (default: 120).
#
# Test targets:
#   * Pass zero targets to run the WHOLE suite: patrol bundles every
#     `*_test.dart` under `patrol_test/` into a single app binary.
#   * Pass one or more targets to run only those files.
#
# Examples:
#   # Run all e2e tests on the first booted simulator:
#   scripts/patrol_ios_simulator.sh
#
#   # Boot a specific simulator, then run tests:
#   scripts/patrol_ios_simulator.sh -s "iPhone 16 Pro"
#
#   # Run a single test:
#   scripts/patrol_ios_simulator.sh patrol_test/smoke/hello_world_test.dart
#
# Notes:
#   * Boot a simulator in Xcode, or pass -s / set IOS_SIMULATOR_DEVICE.
#   * Run from anywhere; paths are resolved relative to this script.

# Note: intentionally not using `pipefail`. A step pipes into `head`, which
# closes the pipe early and would otherwise raise SIGPIPE (exit 141) and abort
# the whole script under `set -e`.
set -eu

usage() {
  echo "Usage: patrol_ios_simulator.sh [-d <udid>] [-s <name>] [--debug|--release] [test_target ...]" >&2
}

# Prints "<name>\t<udid>" for the first booted iPhone simulator, if any.
first_booted_simulator() {
  xcrun simctl list devices booted 2>/dev/null \
    | grep -E '^\s+iPhone' \
    | head -1 \
    | sed -E 's/^[[:space:]]+([^(]+) \(([A-F0-9-]+)\).*/\1\t\2/' \
    | sed 's/[[:space:]]*$//'
}

# Prefer the newest runtime when multiple simulators share the same name.
simulator_udid_for_name() {
  local name="$1"
  xcrun simctl list devices available 2>/dev/null \
    | grep -F "    $name (" \
    | tail -1 \
    | sed -E 's/^[[:space:]]+[^(]+ \(([A-F0-9-]+)\).*/\1/'
}

default_simulator_name() {
  xcrun simctl list devices available 2>/dev/null \
    | grep -E '^\s+iPhone' \
    | tail -1 \
    | sed -E 's/^[[:space:]]+([^(]+) \(.*/\1/' \
    | sed 's/[[:space:]]*$//'
}

boot_simulator() {
  local name="$1"
  local udid
  udid="$(simulator_udid_for_name "$name")"
  if [[ -z "$udid" ]]; then
    echo "ERROR: No simulator named '$name' found." >&2
    echo "       List available devices with: xcrun simctl list devices available" >&2
    exit 1
  fi

  echo "==> Booting simulator: $name ($udid)"
  xcrun simctl boot "$udid" 2>/dev/null || true
  open -a Simulator --args -CurrentDeviceUDID "$udid"

  local timeout="${SIMULATOR_BOOT_TIMEOUT:-120}"
  echo "==> Waiting for simulator to finish booting (timeout ${timeout}s)..."
  xcrun simctl bootstatus "$udid" -b &
  local boot_pid=$!
  local start
  start="$(date +%s)"
  while kill -0 "$boot_pid" 2>/dev/null; do
    if (( $(date +%s) - start > timeout )); then
      kill "$boot_pid" 2>/dev/null || true
      echo "ERROR: Simulator $name ($udid) did not boot within ${timeout}s." >&2
      exit 1
    fi
    sleep 1
  done
  if ! wait "$boot_pid"; then
    echo "ERROR: Simulator $name ($udid) failed to boot." >&2
    exit 1
  fi

  DEVICE_ID="$udid"
  DEVICE_LABEL="$name"
  echo "==> Simulator ready: $name ($udid)"
}

DEVICE_ID=""
DEVICE_LABEL=""
SIMULATOR_NAME=""
BUILD_MODE="--debug"
TEST_TARGETS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device)
      DEVICE_ID="${2:?--device requires a UDID}"
      shift 2
      ;;
    -s|--simulator)
      SIMULATOR_NAME="${2:?--simulator requires a name}"
      shift 2
      ;;
    --debug)
      BUILD_MODE="--debug"
      shift
      ;;
    --release)
      BUILD_MODE="--release"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      TEST_TARGETS+=("$@")
      break
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      TEST_TARGETS+=("$1")
      shift
      ;;
  esac
done

# Resolve the mobile-app root (this script lives in mobile-app/scripts).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$APP_ROOT"

# Pick or boot a simulator.
if [[ -z "$DEVICE_ID" ]]; then
  booted="$(first_booted_simulator || true)"
  if [[ -n "$booted" ]]; then
    DEVICE_LABEL="${booted%%$'\t'*}"
    DEVICE_ID="${booted##*$'\t'}"
    echo "==> Auto-selected booted simulator: $DEVICE_LABEL ($DEVICE_ID)"
  fi
fi

if [[ -z "$DEVICE_ID" ]]; then
  if [[ -z "$SIMULATOR_NAME" ]]; then
    SIMULATOR_NAME="${IOS_SIMULATOR_DEVICE:-$(default_simulator_name || true)}"
  fi
  if [[ -z "$SIMULATOR_NAME" ]]; then
    echo "ERROR: No booted simulator found and no simulator name to boot." >&2
    echo "       Boot one in Xcode, pass -s <name>, or set IOS_SIMULATOR_DEVICE." >&2
    exit 1
  fi
  boot_simulator "$SIMULATOR_NAME"
fi

# Test secrets/fixtures (e.g. TEST_IMPORT_MNEMONIC) are injected at build time via
# --dart-define so they are never bundled into the app as an asset.
#   * Locally: read from a gitignored .env.test (key=value) via --dart-define-from-file.
#   * CI: export TEST_IMPORT_MNEMONIC (and any others) from the runner's secret store.
DART_DEFINES=()
if [[ -f .env.test ]]; then
  echo "==> Injecting test secrets from .env.test"
  DART_DEFINES+=(--dart-define-from-file=.env.test)
elif [[ -n "${TEST_IMPORT_MNEMONIC:-}" ]]; then
  echo "==> Injecting test secrets from environment"
  DART_DEFINES+=(--dart-define=TEST_IMPORT_MNEMONIC="$TEST_IMPORT_MNEMONIC")
else
  echo "WARNING: no .env.test file and TEST_IMPORT_MNEMONIC is unset;" \
       "tests that need a seed phrase (e.g. import_wallet) will fail." >&2
fi

# Build the `-t <target>` flags. With no targets, patrol bundles every
# `*_test.dart` under `patrol_test/`, i.e. the whole suite in one binary.
TARGET_ARGS=()
if [[ ${#TEST_TARGETS[@]} -gt 0 ]]; then
  for target in "${TEST_TARGETS[@]}"; do
    TARGET_ARGS+=(-t "$target")
  done
  echo "==> Test targets: ${TEST_TARGETS[*]}"
else
  echo "==> No targets given; running the WHOLE patrol_test suite."
fi

PATROL_DEVICE="${DEVICE_LABEL:-$DEVICE_ID}"
echo "==> Running Patrol tests on $PATROL_DEVICE ($BUILD_MODE)..."
patrol test \
  --device "$PATROL_DEVICE" \
  "$BUILD_MODE" \
  ${TARGET_ARGS[@]+"${TARGET_ARGS[@]}"} \
  ${DART_DEFINES[@]+"${DART_DEFINES[@]}"}

echo "==> Done."
