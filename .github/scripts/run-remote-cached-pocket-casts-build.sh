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
DERIVED_DATA_PATH="${HOME}/DerivedData"

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
  -project podcasts.xcodeproj \
  -scheme "Pocket Casts Staging" \
  -configuration StagingDebug \
  -destination "generic/platform=iOS Simulator" \
  -showBuildSettings |
grep -E 'DT_TOOLCHAIN_DIR|TOOLCHAIN_DIR|HEADER_SEARCH_PATHS|SDKROOT'

echo "Resolving Swift package dependencies"
xcodebuild \
  -project "${WORKSPACE}/podcasts.xcodeproj" \
  -resolvePackageDependencies \
  -onlyUsePackageVersionsFromResolvedFile

echo "Running Pocket Casts build"
XCODE_XCCONFIG_FILE="$CONFIG_FILE" \
xcodebuild \
  -project "${WORKSPACE}/podcasts.xcodeproj" \
  -scheme "Pocket Casts Staging" \
  -configuration StagingDebug \
  -destination "generic/platform=iOS Simulator" \
  COMPILER_INDEX_STORE_ENABLE=NO \
  build \
  CODE_SIGN_IDENTITY= \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -skipMacroValidation

echo
echo "Remote cache status after build"
(
  cd "$PROJECT_DIR"
  xcodecacheprog status
)
