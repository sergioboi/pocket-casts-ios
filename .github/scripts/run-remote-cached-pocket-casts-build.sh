#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${XCODECACHEPROG_TOKEN:-}" ]]; then
  echo "XCODECACHEPROG_TOKEN is required for remote cache builds" >&2
  exit 1
fi

WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
PROJECT_DIR="$WORKSPACE"
CREDENTIAL_NAME="${XCODECACHEPROG_CREDENTIAL_NAME:-pocket-casts-ios}"
CONFIG_FILE="${PROJECT_DIR}/XcodeRemoteCache.xcconfig"
DERIVED_DATA_PATH="${POCKET_CASTS_DERIVED_DATA_PATH:-${HOME}/DerivedData}"

if [[ ! -d "${PROJECT_DIR}/.xcodecacheprog" ]]; then
  echo ".xcodecacheprog is required for remote cache builds" >&2
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "XcodeRemoteCache.xcconfig is required for remote cache builds" >&2
  exit 1
fi

echo "Configuring Xcode remote compilation cache"
(
  cd "$PROJECT_DIR"
  xcodecacheprog sync \
    --credential-name "$CREDENTIAL_NAME" \
    --credential-env XCODECACHEPROG_TOKEN
)

echo "Removing Pocket Casts DerivedData before build"
rm -rf "$DERIVED_DATA_PATH"
rm -rf "${HOME}/Library/Developer/Xcode/DerivedData"

echo "Remote cache status before build"
(
  cd "$PROJECT_DIR"
  xcodecacheprog status
)

echo "=== Xcode selection ==="
xcode-select -p
xcodebuild -version

echo "=== Effective settings ==="
XCODE_XCCONFIG_FILE="$CONFIG_FILE" \
xcodebuild \
  -project "${WORKSPACE}/${POCKET_CASTS_PROJECT:-podcasts.xcodeproj}" \
  -scheme "${POCKET_CASTS_SCHEME:-Pocket Casts Staging}" \
  -configuration "${POCKET_CASTS_CONFIGURATION:-StagingDebug}" \
  -destination "generic/platform=iOS Simulator" \
  -showBuildSettings |
grep -E 'DT_TOOLCHAIN_DIR|TOOLCHAIN_DIR|HEADER_SEARCH_PATHS|SDKROOT'

echo "Resolving Swift package dependencies"
xcodebuild \
  -project "${WORKSPACE}/${POCKET_CASTS_PROJECT:-podcasts.xcodeproj}" \
  -resolvePackageDependencies \
  -onlyUsePackageVersionsFromResolvedFile

echo "Running Pocket Casts build-for-testing"
XCODE_XCCONFIG_FILE="$CONFIG_FILE" \
"${WORKSPACE}/.github/scripts/run-pocket-casts-build-for-testing.sh"

echo
echo "Remote cache status after build"
(
  cd "$PROJECT_DIR"
  xcodecacheprog status
)
