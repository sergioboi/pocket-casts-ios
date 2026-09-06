#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PROJECT="${POCKET_CASTS_PROJECT:-podcasts.xcodeproj}"
SCHEME="${POCKET_CASTS_SCHEME:-Pocket Casts Staging}"
CONFIGURATION="${POCKET_CASTS_CONFIGURATION:-StagingDebug}"
TEST_PLAN="${POCKET_CASTS_TEST_PLAN:-UnitTests}"
DESTINATION="${POCKET_CASTS_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"
DERIVED_DATA_PATH="${POCKET_CASTS_DERIVED_DATA_PATH:-${HOME}/DerivedData}"
BUILD_TASK="${POCKET_CASTS_BUILD_TASK:-build-for-testing}"
PROJECT_PATH="${REPO_ROOT}/${PROJECT}"

case "$BUILD_TASK" in
  build|build-for-testing)
    ;;
  *)
    echo "Unsupported Pocket Casts build task: $BUILD_TASK" >&2
    exit 1
    ;;
esac

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Pocket Casts Xcode project not found: $PROJECT_PATH" >&2
  exit 1
fi

echo "=== Pocket Casts ${BUILD_TASK} ==="
echo "Project:       $PROJECT_PATH"
echo "Scheme:        $SCHEME"
echo "Configuration: $CONFIGURATION"
echo "Test plan:     $TEST_PLAN"
echo "Destination:   $DESTINATION"
echo "DerivedData:   $DERIVED_DATA_PATH"
echo "Xcode config:  ${XCODE_XCCONFIG_FILE:-none}"

XCODEBUILD_ARGS=(
  -project "$PROJECT_PATH"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "$DESTINATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
  -skipMacroValidation
)

if [[ "$BUILD_TASK" == "build-for-testing" ]]; then
  XCODEBUILD_ARGS+=(
    -testPlan "$TEST_PLAN"
  )
fi

if [[ -n "${XCODE_XCCONFIG_FILE:-}" ]]; then
  XCODEBUILD_ARGS+=(
    -xcconfig "$XCODE_XCCONFIG_FILE"
  )
fi

XCODEBUILD_ARGS+=(
  "$BUILD_TASK"
  COMPILER_INDEX_STORE_ENABLE=NO
  CODE_SIGN_IDENTITY=
  CODE_SIGNING_REQUIRED=NO
  CODE_SIGNING_ALLOWED=NO
  "$@"
)

xcodebuild "${XCODEBUILD_ARGS[@]}"

PRODUCTS_DIR="${DERIVED_DATA_PATH}/Build/Products"

if [[ "$BUILD_TASK" == "build" ]]; then
  exit 0
fi

if [[ ! -d "$PRODUCTS_DIR" ]]; then
  echo "Build products not found after build: $PRODUCTS_DIR" >&2
  exit 1
fi

XCTESTRUN_FILE="$(
  find "$PRODUCTS_DIR" \
    -maxdepth 1 \
    -type f \
    -name "*_${TEST_PLAN}_*.xctestrun" \
    -print \
    -quit
)"

if [[ -z "$XCTESTRUN_FILE" ]]; then
  echo "Expected ${TEST_PLAN} .xctestrun was not generated." >&2
  echo "Available .xctestrun files:" >&2

  find "$PRODUCTS_DIR" \
    -maxdepth 1 \
    -type f \
    -name '*.xctestrun' \
    -print >&2 || true

  exit 1
fi

echo
echo "Generated XCTest run file:"
echo "$XCTESTRUN_FILE"
