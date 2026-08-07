#!/bin/sh

# 에러 발생 시 즉시 종료
set -e

# 1. 저장소 최상단 경로 확보
ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

# 2. Staged 상태인 Swift 파일 목록 추출
staged_swift_files=$(git diff --cached --name-only --diff-filter=ACMR | grep "\.swift$" || true)

if [ -z "$staged_swift_files" ]; then
	echo "포맷팅 대상 파일이 없습니다."
	exit 0
fi

# 3. Staged Swift 파일만 포맷팅 (툴체인 내장 swift-format, 패키지 의존 없음)
echo "Staged Swift 파일들에 대해 포맷팅을 실행합니다..."
cd "$ROOT_DIR"
for file in $staged_swift_files; do
	swift format format --in-place "$file"
done

# 4. 포맷팅 후 변경 사항 확인 및 가이드 출력
cd "$ROOT_DIR"
for file in $staged_swift_files; do
	if ! git diff --quiet -- "$file"; then
		echo "오류: 포맷팅으로 인해 $file 파일이 변경되었습니다." >&2
		echo "조치: 변경사항을 git add 한 후 다시 커밋해 주세요." >&2
		exit 1
	fi
done

echo "Swift 포맷팅 검증 완료."
