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
rg -q '^  project-validation:' "$workflow"
validation_job=$(sed -n '/^  project-validation:/,/^  gate:/p' "$workflow")
printf '%s\n' "$validation_job" | rg -q 'PROJECT_BUILD_RUNNER.*build'
printf '%s\n' "$validation_job" | rg -q 'PROJECT_BUILD_RUNNER.*compile-unit'
printf '%s\n' "$validation_job" | rg -q 'PROJECT_BUILD_RUNNER.*test-unit'
compile_line=$(printf '%s\n' "$validation_job" | rg -n 'PROJECT_BUILD_RUNNER.*compile-unit' | cut -d: -f1)
test_line=$(printf '%s\n' "$validation_job" | rg -n 'PROJECT_BUILD_RUNNER.*test-unit' | cut -d: -f1)
[ "$compile_line" -lt "$test_line" ] || {
	printf 'FAIL: unit test가 컴파일보다 먼저 실행됩니다\n' >&2
	exit 1
}
printf '%s\n' "$validation_job" | rg -q "project_config_changed == 'true'"
if printf '%s\n' "$validation_job" | rg -q 'actions/cache/(save|restore)@v4|TestSchemes/\*/Build/Products'; then
	printf 'FAIL: 통합 job이 컴파일 산출물을 불필요하게 전송합니다\n' >&2
	exit 1
fi
rg -q 'needs\.project-validation\.result' "$workflow"
if rg -n '^[[:space:]]+(app-build|unit-compile|unit-tests|ui-compile|ui-tests):|test-ui|compile-ui' "$workflow" >/dev/null; then
	printf 'FAIL: CI workflow에 중복 project job이 남아 있습니다\n' >&2
	exit 1
fi

printf 'PASS: CI gate evaluator\n'
