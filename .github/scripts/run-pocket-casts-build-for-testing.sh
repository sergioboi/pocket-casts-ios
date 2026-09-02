#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PROJECT="${POCKET_CASTS_PROJECT:-podcasts.xcodeproj}"
SCHEME="${POCKET_CASTS_SCHEME:-Pocket Casts Staging}"
CONFIGURATION="${POCKET_CASTS_CONFIGURATION:-StagingDebug}"
TEST_PLAN="${POCKET_CASTS_TEST_PLAN:-UnitTests}"
DESTINATION="${POCKET_CASTS_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"
DERIVED_DATA_PATH="${POCKET_CASTS_DERIVED_DATA_PATH:-${HOME}/DerivedData}"

PROJECT_PATH="${REPO_ROOT}/${PROJECT}"
PRODUCTS_DIR="${DERIVED_DATA_PATH}/Build/Products"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Pocket Casts Xcode project not found: $PROJECT_PATH" >&2
  exit 1
fi

echo "=== Pocket Casts build-for-testing ==="
echo "Project:       $PROJECT_PATH"
echo "Scheme:        $SCHEME"
echo "Configuration: $CONFIGURATION"
echo "Test plan:     $TEST_PLAN"
echo "Destination:   $DESTINATION"
echo "DerivedData:   $DERIVED_DATA_PATH"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -testPlan "$TEST_PLAN" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -skipMacroValidation \
  build-for-testing \
  COMPILER_INDEX_STORE_ENABLE=NO \
  CODE_SIGN_IDENTITY= \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  "$@"

if [[ ! -d "$PRODUCTS_DIR" ]]; then
  echo "Build products not found: $PRODUCTS_DIR" >&2
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
