#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

POCKET_CASTS_BUILD_TASK=build-for-testing \
  exec "${REPO_ROOT}/.github/scripts/run-pocket-casts-build.sh" "$@"
