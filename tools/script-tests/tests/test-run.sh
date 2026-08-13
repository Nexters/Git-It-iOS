#!/bin/sh
# shellcheck disable=SC1090,SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
work=$(mktemp -d "${TMPDIR:-/tmp}/script-tests-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
. "$module/core/tests.sh"
. "$module/core/run.sh"

# 격리 저장소의 모든 모듈 테스트를 공개 실행 계약과 같은 방식으로 실행합니다.
repository="$work/저장소 경로"
mkdir -p "$repository/tools/one/tests" "$repository/tools/two/tests"
printf '%s\n' '#!/bin/sh' 'printf "first\\n"' >"$repository/tools/one/tests/test-one.sh"
printf '%s\n' '#!/bin/sh' 'printf "second\\n"' >"$repository/tools/two/tests/test-two.sh"
# shellcheck disable=SC2016
printf '%s\n' '#!/bin/sh' \
	'[ -z "${GIT_IT_HOOKS_ROOT:-}" ] || exit 1' \
	'[ -z "${GIT_DIR:-}" ] || exit 1' \
	'printf isolated\\n' >"$repository/tools/two/tests/test-environment.sh"
GIT_IT_HOOKS_ROOT='외부 훅 경로'
GIT_DIR="$work/outside-git-dir"
export GIT_IT_HOOKS_ROOT GIT_DIR
script_tests_run "$repository" "$work/run" script_tests_collect script_tests_execute >"$work/out"
unset GIT_IT_HOOKS_ROOT GIT_DIR
rg -q '^first$' "$work/out"
rg -q '^second$' "$work/out"
rg -q '^isolated$' "$work/out"
rg -q '^스크립트 테스트 완료$' "$work/out"

empty_repository="$work/empty"
mkdir -p "$empty_repository/tools"
if script_tests_run "$empty_repository" "$work/empty-run" script_tests_collect script_tests_execute >"$work/empty-out" 2>"$work/empty-err"; then
	printf 'FAIL: 테스트 없는 저장소를 성공으로 반환\n' >&2
	exit 1
else result=$?; fi
[ "$result" -eq 2 ]
rg -q 'script-tests.no-tests' "$work/empty-err"
printf 'PASS: script tests runner\n'
