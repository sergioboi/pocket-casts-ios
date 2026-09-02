#!/usr/bin/env bash

set -euo pipefail

TEST_PLAN="${POCKET_CASTS_TEST_PLAN:-UnitTests}"
DESTINATION="${POCKET_CASTS_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"
DERIVED_DATA_PATH="${POCKET_CASTS_DERIVED_DATA_PATH:-${HOME}/DerivedData}"

PRODUCTS_DIR="${DERIVED_DATA_PATH}/Build/Products"

if [[ ! -d "$PRODUCTS_DIR" ]]; then
  echo "Build products not found: $PRODUCTS_DIR" >&2
  echo "Run build-for-testing first." >&2
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
  echo "No ${TEST_PLAN} .xctestrun found." >&2
  echo "Available .xctestrun files:" >&2

  find "$PRODUCTS_DIR" \
    -maxdepth 1 \
    -type f \
    -name '*.xctestrun' \
    -print >&2 || true

  exit 1
fi

RESULT_BUNDLE_PATH="${POCKET_CASTS_RESULT_BUNDLE_PATH:-${RUNNER_TEMP:-/tmp}/pocket-casts-${TEST_PLAN}.xcresult}"

rm -rf "$RESULT_BUNDLE_PATH"

echo "=== Pocket Casts test-without-building ==="
echo "XCTest run:    $XCTESTRUN_FILE"
echo "Destination:   $DESTINATION"
echo "Result bundle: $RESULT_BUNDLE_PATH"

xcodebuild \
  test-without-building \
  -xctestrun "$XCTESTRUN_FILE" \
  -destination "$DESTINATION" \
  -resultBundlePath "$RESULT_BUNDLE_PATH" \
  "$@"
