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

# lint 병렬화, build → compile → test 선행 관계와 5개 macOS shard 상한을 고정합니다.
rg -q "needs\.changes\.outputs\.build_required == 'true'" "$workflow"
rg -Fq '    name: lint (${{ matrix.project }})' "$workflow"
rg -Fq 'lint "$GIT_IT_PROJECTS_ROOT/$GIT_IT_LINT_PROJECT"' "$workflow"
[ "$(rg -o '"project":"[A-Za-z]+"' "$workflow" | wc -l | tr -d ' ')" -eq 7 ]
rg -q '^  unit-compile:$' "$workflow"
rg -q '^  ui-compile:$' "$workflow"
rg -q '^      - app-build$' "$workflow"
rg -q '^      - unit-compile$' "$workflow"
rg -q '^      - ui-compile$' "$workflow"
[ "$(rg -c '^      max-parallel: 5$' "$workflow")" -eq 4 ]
rg -q 'actions/upload-artifact@v4' "$workflow"
rg -q 'actions/download-artifact@v4' "$workflow"
rg -q 'GIT_IT_TEST_TARGET:' "$workflow"

printf 'PASS: CI gate evaluator\n'
