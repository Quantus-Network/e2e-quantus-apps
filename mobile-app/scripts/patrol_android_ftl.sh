#!/usr/bin/env bash
#
# Upload pre-built Patrol Android APKs to Firebase Test Lab and run them.
#
# Expects `patrol build android` to have already produced:
#   build/app/outputs/apk/debug/app-debug.apk
#   build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
#
# Usage:
#   scripts/patrol_android_ftl.sh [options]
#
# Options:
#   --timeout <duration>   FTL timeout (default: 30m).
#   --device <spec>        FTL device spec (default: MediumPhone.arm API 34).
#   --project <id>         GCP/Firebase project (default: GCP_PROJECT or quantus-wallet).
#   -h, --help             Show this help.
#
# Environment:
#   GCP_PROJECT            Firebase/GCP project id (default: quantus-wallet).
#   GITHUB_RUN_ID          Used in --results-dir when running in Actions.
#
# Examples:
#   patrol build android --debug -t patrol_test/flows/create_wallet_test.dart
#   scripts/patrol_android_ftl.sh
#
# Notes:
#   * Requires `gcloud` authenticated with Firebase Test Lab Admin on the project.
#   * Run from anywhere; paths are resolved relative to this script.

set -eu

# shellcheck source=lib/patrol_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/patrol_common.sh"

TIMEOUT="30m"
DEVICE_SPEC="model=MediumPhone.arm,version=34,locale=en,orientation=portrait"
PROJECT_ID="${GCP_PROJECT:-quantus-wallet}"

APP_APK="build/app/outputs/apk/debug/app-debug.apk"
TEST_APK="build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"

usage() {
  echo "Usage: patrol_android_ftl.sh [--timeout <duration>] [--device <spec>] [--project <id>]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout)
      TIMEOUT="${2:?--timeout requires a duration}"
      shift 2
      ;;
    --device)
      DEVICE_SPEC="${2:?--device requires a device spec}"
      shift 2
      ;;
    --project)
      PROJECT_ID="${2:?--project requires a project id}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

patrol_resolve_app_root "${BASH_SOURCE[0]}"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "ERROR: gcloud not found. Install the Google Cloud SDK and authenticate." >&2
  exit 1
fi

if [[ ! -f "$APP_APK" ]]; then
  echo "ERROR: missing app APK: $APP_APK" >&2
  echo "       Run \`patrol build android\` first." >&2
  exit 1
fi

if [[ ! -f "$TEST_APK" ]]; then
  echo "ERROR: missing test APK: $TEST_APK" >&2
  echo "       Run \`patrol build android\` first." >&2
  exit 1
fi

RESULTS_DIR="patrol_${GITHUB_RUN_ID:-local}_$(date +%s)"

echo "==> Running Patrol Android tests on Firebase Test Lab"
echo "    project:  $PROJECT_ID"
echo "    device:   $DEVICE_SPEC"
echo "    timeout:  $TIMEOUT"
echo "    app:      $APP_APK"
echo "    test:     $TEST_APK"
echo "    results:  $RESULTS_DIR"

gcloud firebase test android run \
  --project="$PROJECT_ID" \
  --type=instrumentation \
  --use-orchestrator \
  --app="$APP_APK" \
  --test="$TEST_APK" \
  --timeout="$TIMEOUT" \
  --device="$DEVICE_SPEC" \
  --record-video \
  --environment-variables=clearPackageData=true \
  --results-dir="$RESULTS_DIR"

echo "==> Done. Results dir: $RESULTS_DIR"
