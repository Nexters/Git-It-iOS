#!/bin/sh

# 에러 발생 시 즉시 종료
set -e

# 1. 저장소 최상단 경로 확보
ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

# 2. 빌드 스크립트 실행
./.githooks/project-build/bin/run.sh build
