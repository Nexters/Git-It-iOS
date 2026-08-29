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
if rg -n 'continue-on-error: true' "$workflow" >/dev/null; then
	printf 'FAIL: CI job이 오류를 성공으로 처리합니다\n' >&2
	exit 1
fi
rg -q 'continue-on-error: false' "$workflow"
rg -q "vars.GIT_IT_CI_VALIDATION_ENABLED == 'true'" "$workflow"
rg -q 'lint-changed-swift\.sh' "$workflow"
rg -q 'needs\.swift-lint\.result' "$workflow"
rg -q 'GIT_IT_SCRIPT_VERIFICATION_RUNNER' "$workflow"

# build -> compile -> test가 분리된 job으로, 이 순서의 needs 의존을 유지하는지 고정합니다.
rg -q '^  build:' "$workflow"
rg -q '^  compile:' "$workflow"
rg -q '^  test:' "$workflow"
build_job=$(sed -n '/^  build:/,/^  compile:/p' "$workflow")
compile_job=$(sed -n '/^  compile:/,/^  test:/p' "$workflow")
test_job=$(sed -n '/^  test:/,/^  gate:/p' "$workflow")
printf '%s\n' "$build_job" | rg -q 'PROJECT_BUILD_RUNNER.*build$'
printf '%s\n' "$compile_job" | rg -q 'PROJECT_BUILD_RUNNER.*compile$'
printf '%s\n' "$test_job" | rg -q 'PROJECT_BUILD_RUNNER.*test$'
printf '%s\n' "$compile_job" | rg -q '^\s*-\s*build\s*$'
printf '%s\n' "$test_job" | rg -q '^\s*-\s*compile\s*$'
printf '%s\n' "$build_job" | rg -q "project_config_changed == 'true'"

# test job이 패키지별 scheme으로 병렬 matrix 실행되는지 고정합니다.
printf '%s\n' "$test_job" | rg -q 'strategy:'
printf '%s\n' "$test_job" | rg -q 'fail-fast: false'
printf '%s\n' "$test_job" | rg -q 'matrix:'
printf '%s\n' "$test_job" | rg -q 'GIT_IT_ONLY_SCHEME:\s*\$\{\{\s*matrix\.scheme\s*\}\}'
rg -q 'testable_schemes' "$workflow"

# compile이 만든 산출물을 test matrix가 재사용하는지(재빌드 없이) 고정합니다.
printf '%s\n' "$compile_job" | rg -q 'actions/upload-artifact@v4'
printf '%s\n' "$test_job" | rg -q 'actions/download-artifact@v4'

rg -q 'needs\.build\.result' "$workflow"
rg -q 'needs\.compile\.result' "$workflow"
rg -q 'needs\.test\.result' "$workflow"
if rg -n '^  project-validation:' "$workflow" >/dev/null; then
	printf 'FAIL: 이전 통합 project-validation job이 남아 있습니다\n' >&2
	exit 1
fi
if rg -n '^[[:space:]]+(app-build|unit-compile|unit-tests|ui-compile|ui-tests):|test-ui|compile-ui' "$workflow" >/dev/null; then
	printf 'FAIL: CI workflow에 중복 project job이 남아 있습니다\n' >&2
	exit 1
fi

printf 'PASS: CI gate evaluator\n'
