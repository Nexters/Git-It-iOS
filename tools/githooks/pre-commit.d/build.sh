#!/bin/sh

# 에러 발생 시 즉시 종료
set -e

# 1. 단계 스크립트 자신의 위치에서 실행 저장소를 찾습니다.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd -P)
PATHS="$ROOT_DIR/tools/repository-paths/bin/repository-paths.sh"
RUNNER=$("$PATHS" --absolute GIT_IT_PROJECT_BUILD_RUNNER)
cd "$ROOT_DIR"

# 2. 빌드 스크립트 실행
"$RUNNER" build
