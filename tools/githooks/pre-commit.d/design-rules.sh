#!/bin/sh
set -e

# 단계 스크립트 자신의 위치에서 실행 저장소와 공개 검사 명령을 찾습니다.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd -P)
PATHS="$ROOT_DIR/tools/repository-paths/bin/repository-paths.sh"
RUNNER=$("$PATHS" --absolute GIT_IT_DESIGN_RULE_RUNNER)
cd "$ROOT_DIR"

# 디자인 규격의 금지 패턴을 공개 진입점으로 검사합니다.
"$RUNNER"
