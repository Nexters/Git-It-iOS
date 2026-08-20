#!/bin/sh
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
gate="$module/bin/gate-evaluate.sh"
workflow="$root/.github/workflows/ci.yml"
work=$(mktemp -d "${TMPDIR:-/tmp}/ci-gate-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM

# success와 조건부 skipped만 있으면 gate를 통과합니다.
GITHUB_STEP_SUMMARY="$work/summary" "$gate" success skipped success skipped \
	>"$work/out" 2>"$work/err"
rg -q '평가 통과' "$work/out"
rg -Fq '| ✅ 성공 (Success) | 2 |' "$work/summary"
rg -Fq '| ⏭️ 생략 (Skipped) | 2 |' "$work/summary"

# 변경 분류기 failure 뒤 후속 job이 skipped여도 gate는 실패해야 합니다.
if "$gate" failure skipped skipped skipped skipped >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 변경 분류기 실패를 성공으로 반환\n' >&2
	exit 1
else
	result=$?
fi
[ "$result" -eq 1 ]
rg -q '평가 실패: 1개 job 실패' "$work/out"

# 알 수 없는 GitHub job 결과는 입력 오류로 처리합니다.
if "$gate" success timed_out >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 알 수 없는 job 결과를 성공으로 반환\n' >&2
	exit 1
else
	result=$?
fi
[ "$result" -eq 2 ]
rg -q 'ci.gate-evaluate.unknown-result' "$work/err"

# workflow가 변경 분류기 결과를 evaluator에 전달하는지 함께 고정합니다.
rg -q 'needs\.changes\.result' "$workflow"

# 단일 build → compile → test job과 컴파일 산출물 전달 계약을 고정합니다.
rg -q "needs\.changes\.outputs\.build_required == 'true'" "$workflow"
rg -q "needs\.changes\.outputs\.tests_required == 'true'" "$workflow"
rg -q '^  app-build:$' "$workflow"
rg -q '^  test-compile:$' "$workflow"
rg -q '^  tests:$' "$workflow"
rg -A 5 '^  test-compile:$' "$workflow" | rg -q '^      - app-build$'
rg -A 5 '^  tests:$' "$workflow" | rg -q '^      - test-compile$'
if rg -q 'matrix\.|max-parallel:|GIT_IT_PROJECT_SCHEME:|GIT_IT_TEST_TARGET:' "$workflow"; then
	printf 'FAIL: job 단위 분할 설정이 남아 있음\n' >&2
	exit 1
fi
rg -Fq '"$GIT_IT_PROJECT_BUILD_RUNNER" build' "$workflow"
rg -Fq '"$GIT_IT_PROJECT_BUILD_RUNNER" compile' "$workflow"
rg -Fq '"$GIT_IT_PROJECT_BUILD_RUNNER" test' "$workflow"
rg -q 'actions/upload-artifact@v4' "$workflow"
rg -q 'actions/download-artifact@v4' "$workflow"
rg -q 'name: compiled-test-products' "$workflow"
rg -Fq 'GIT_IT_DERIVED_DATA_PATH/TestSchemes' "$workflow"
rg -Fq 'cd "$GIT_IT_DERIVED_DATA_PATH/TestSchemes"' "$workflow"
rg -Fq './*/Build/Products' "$workflow"

printf 'PASS: CI gate evaluator\n'
