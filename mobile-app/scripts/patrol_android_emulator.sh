#!/usr/bin/env bash
#
# Run Patrol E2E tests on an Android emulator.
#
# Android counterpart of scripts/patrol_ios_device.sh, scoped to emulators for
# local E2E runs. Unlike iOS physical devices, `patrol test` can build and run
# in one step on Android without the xcodebuild destination-timeout workaround.
#
# Usage:
#   scripts/patrol_android_emulator.sh [options] [test_target ...]
#
# Options:
#   -d, --device <serial>   Emulator serial (default: first running emulator).
#   -a, --avd <name>        Start this AVD when no emulator is running.
#       --debug             Build a debug binary (default).
#       --release           Build a release binary.
#
# Environment:
#   ANDROID_EMULATOR_AVD    Default AVD to boot when none is running and -a
#                           is not passed (falls back to the first listed AVD).
#   EMULATOR_BOOT_TIMEOUT   Seconds to wait for boot (default: 120).
#
# Test targets:
#   * Pass zero targets to run the WHOLE suite: patrol bundles every
#     `*_test.dart` under `patrol_test/` into a single app binary.
#   * Pass one or more targets to run only those files.
#
# Examples:
#   # Run all e2e tests on the first running emulator:
#   scripts/patrol_android_emulator.sh
#
#   # Boot a specific AVD, then run tests:
#   scripts/patrol_android_emulator.sh -a Pixel_8_API_35
#
#   # Run a single test:
#   scripts/patrol_android_emulator.sh patrol_test/smoke/hello_world_test.dart
#
# Notes:
#   * Start an emulator in Android Studio, or pass -a / set ANDROID_EMULATOR_AVD.
#   * Run from anywhere; paths are resolved relative to this script.

# Note: intentionally not using `pipefail`. A step pipes into `head`, which
# closes the pipe early and would otherwise raise SIGPIPE (exit 141) and abort
# the whole script under `set -e`.
set -eu

usage() {
  echo "Usage: patrol_android_emulator.sh [-d <serial>] [-a <avd>] [--debug|--release] [test_target ...]" >&2
}

first_running_emulator() {
  adb devices 2>/dev/null | awk '$2 == "device" && $1 ~ /^emulator-/ {print $1; exit}'
}

first_listed_avd() {
  if ! command -v emulator >/dev/null 2>&1; then
    return 1
  fi
  emulator -list-avds 2>/dev/null | head -1
}

wait_for_emulator_boot() {
  local serial="$1"
  local timeout="${EMULATOR_BOOT_TIMEOUT:-120}"
  echo "==> Waiting for $serial to finish booting (timeout ${timeout}s)..."
  adb -s "$serial" wait-for-device
  local start
  start="$(date +%s)"
  while true; do
    local boot_completed
    boot_completed="$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
    if [[ "$boot_completed" == "1" ]]; then
      echo "==> Emulator ready: $serial"
      return 0
    fi
    if (( $(date +%s) - start > timeout )); then
      echo "ERROR: Emulator $serial did not boot within ${timeout}s." >&2
      exit 1
    fi
    sleep 2
  done
}

start_emulator() {
  local avd_name="$1"
  if ! command -v emulator >/dev/null 2>&1; then
    echo "ERROR: \`emulator\` not found. Install the Android SDK emulator or" \
         "start an AVD from Android Studio." >&2
    exit 1
  fi

  echo "==> Starting emulator: $avd_name"
  emulator -avd "$avd_name" -no-snapshot-load >/dev/null 2>&1 &
  local start
  start="$(date +%s)"
  local timeout="${EMULATOR_BOOT_TIMEOUT:-120}"
  while true; do
    local serial
    serial="$(first_running_emulator || true)"
    if [[ -n "$serial" ]]; then
      wait_for_emulator_boot "$serial"
      DEVICE_SERIAL="$serial"
      return 0
    fi
    if (( $(date +%s) - start > timeout )); then
      echo "ERROR: Emulator process started but no serial appeared within ${timeout}s." >&2
      exit 1
    fi
    sleep 2
  done
}

DEVICE_SERIAL=""
AVD_NAME=""
BUILD_MODE="--debug"
TEST_TARGETS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device)
      DEVICE_SERIAL="${2:?--device requires a serial}"
      shift 2
      ;;
    -a|--avd)
      AVD_NAME="${2:?--avd requires a name}"
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

# Pick or boot an emulator.
if [[ -z "$DEVICE_SERIAL" ]]; then
  DEVICE_SERIAL="$(first_running_emulator || true)"
  if [[ -n "$DEVICE_SERIAL" ]]; then
    echo "==> Auto-selected running emulator: $DEVICE_SERIAL"
  fi
fi

if [[ -z "$DEVICE_SERIAL" ]]; then
  if [[ -z "$AVD_NAME" ]]; then
    AVD_NAME="${ANDROID_EMULATOR_AVD:-$(first_listed_avd || true)}"
  fi
  if [[ -z "$AVD_NAME" ]]; then
    echo "ERROR: No running emulator found and no AVD to boot." >&2
    echo "       Start one in Android Studio, pass -a <avd>, or set ANDROID_EMULATOR_AVD." >&2
    exit 1
  fi
  start_emulator "$AVD_NAME"
fi

if [[ "$DEVICE_SERIAL" != emulator-* ]]; then
  echo "WARNING: $DEVICE_SERIAL does not look like an emulator serial." >&2
fi

# Test secrets/fixtures (TEST_IMPORT_MNEMONIC, TEST_SEND_RECIPIENT_ADDRESS) are injected
# at build time via --dart-define so they are never bundled into the app as an asset.
#   * Locally: read from a gitignored .env.test (key=value) via --dart-define-from-file.
#   * CI: export vars from the runner's secret store.
#
# send_flow_test: emulator only; keep fingerprint NOT enrolled so LocalAuthentication
# auto-passes on Confirm.
DART_DEFINES=()
if [[ -f .env.test ]]; then
  echo "==> Injecting test secrets from .env.test"
  DART_DEFINES+=(--dart-define-from-file=.env.test)
elif [[ -n "${TEST_IMPORT_MNEMONIC:-}" ]]; then
  echo "==> Injecting test secrets from environment"
  DART_DEFINES+=(--dart-define=TEST_IMPORT_MNEMONIC="$TEST_IMPORT_MNEMONIC")
  if [[ -n "${TEST_SEND_RECIPIENT_ADDRESS:-}" ]]; then
    DART_DEFINES+=(--dart-define=TEST_SEND_RECIPIENT_ADDRESS="$TEST_SEND_RECIPIENT_ADDRESS")
  fi
else
  echo "WARNING: no .env.test file and TEST_IMPORT_MNEMONIC is unset;" \
       "tests that need a seed phrase (e.g. import_wallet, send_flow) will fail." >&2
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

echo "==> Running Patrol tests on $DEVICE_SERIAL ($BUILD_MODE)..."
patrol test \
  --device "$DEVICE_SERIAL" \
  "$BUILD_MODE" \
  ${TARGET_ARGS[@]+"${TARGET_ARGS[@]}"} \
  ${DART_DEFINES[@]+"${DART_DEFINES[@]}"}

echo "==> Done."
