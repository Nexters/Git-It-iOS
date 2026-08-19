#!/bin/sh
# shellcheck disable=SC1091

set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
. "$module/core/scheme-policy.sh"
. "$module/core/run-all.sh"
root=$(CDPATH='' cd -- "$module/../../.." && pwd -P)
paths="$root/tools/repository-paths/bin/repository-paths.sh"
projects="/repo/$("$paths" GIT_IT_PROJECTS_ROOT)"
workspace="/repo/$("$paths" GIT_IT_WORKSPACE_PATH)"

assert_equal() {
	[ "$1" = "$2" ] || {
		printf 'FAIL: %s expected=%s actual=%s\n' "$3" "$1" "$2" >&2
		exit 1
	}
}

assert_equal eligible "$(scheme_policy_decide "$projects" "$workspace" "$projects/App/xcshareddata/xcschemes/App.xcscheme" all false)" '공유 scheme 선택'
assert_equal eligible "$(scheme_policy_decide "$projects" "$workspace" "$workspace/xcshareddata/xcschemes/App.xcscheme" all false)" 'workspace 공유 scheme 선택'
assert_equal ineligible "$(scheme_policy_decide "$projects" "$workspace" /repo/Private/App.xcscheme all false)" '경계 밖 scheme 제외'
assert_equal eligible "$(scheme_policy_decide "$projects" "$workspace" "$projects/App/xcshareddata/xcschemes/App.xcscheme" testable true)" '테스트 scheme 선택'
assert_equal ineligible "$(scheme_policy_decide "$projects" "$workspace" "$projects/App/xcshareddata/xcschemes/App.xcscheme" testable false)" '비테스트 scheme 제외'
assert_equal eligible "$(scheme_policy_match_name '' App)" '빈 scheme 선택자는 전체 허용'
assert_equal eligible "$(scheme_policy_match_name App App)" '동일한 scheme 선택'
assert_equal ineligible "$(scheme_policy_match_name App Domain)" '다른 scheme 제외'
assert_equal build "$(scheme_policy_xcode_action build)" 'build action'
assert_equal build-for-testing "$(scheme_policy_xcode_action compile)" 'compile action'
assert_equal test-without-building "$(scheme_policy_xcode_action test)" 'test action'
assert_equal failed "$(scheme_policy_aggregate 3 1)" '일부 실패 집계'
assert_equal skipped "$(scheme_policy_aggregate 0 0)" '대상 없음 집계'

call_log=/tmp/project-action-call-log.$$
: >"$call_log"
fake_workspace() {
	printf 'observe\n' >>"$call_log"
	printf 'App\0Domain\0' >"$2"
}
fake_xcodebuild() {
	printf 'execute\n' >>"$call_log"
	: >"$2"
}
project_run_all fake_workspace fake_xcodebuild /tmp/project-observed.$$ /tmp/project-targets.$$ /tmp/project-results.$$
assert_equal 'observe
execute' "$(cat "$call_log")" 'workspace/xcodebuild port 호출'
rm -f /tmp/project-observed.$$ /tmp/project-targets.$$ /tmp/project-results.$$ "$call_log"
printf 'PASS: project-build core\n'
