#!/bin/sh

# 에러 발생 시 즉시 종료
set -e

# 1. 저장소 최상단 경로 확보
ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

# 2. Swift-Format 진입점으로 staged 포맷팅 실행
./.githooks/swift-format/bin/run.sh staged
