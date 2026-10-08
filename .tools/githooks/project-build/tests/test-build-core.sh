#!/bin/sh
# shellcheck disable=SC1091

set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
. "$module/core/scheme-policy.sh"
. "$module/core/run-all.sh"
root=$(CDPATH='' cd -- "$module/../../.." && pwd -P)
paths="$root/.tools/repository-paths/bin/repository-paths.sh"
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
assert_equal ineligible "$(scheme_policy_decide "$projects" "$workspace" "$projects/UI/xcshareddata/xcschemes/UI.xcscheme" unit true)" 'unit 범위에서 개별 scheme 제외'
assert_equal ineligible "$(scheme_policy_decide "$projects" "$workspace" "$projects/UI/xcshareddata/xcschemes/UI.xcscheme" ui true)" 'UI 자동화 target이 없으면 UI 범위 제외'
assert_equal eligible "$(scheme_policy_decide "$projects" "$workspace" "$projects/App/xcshareddata/xcschemes/App.xcscheme" app true)" '대표 App scheme 선택'
assert_equal ineligible "$(scheme_policy_decide "$projects" "$workspace" "$workspace/xcshareddata/xcschemes/AllTests.xcscheme" testable true)" 'testable 범위에서 AllTests 중복 실행 제외'
assert_equal eligible "$(scheme_policy_decide "$projects" "$workspace" "$workspace/xcshareddata/xcschemes/AllTests.xcscheme" unit true)" 'unit 범위에서 AllTests aggregate 선택'
assert_equal ineligible "$(scheme_policy_decide "$projects" "$workspace" "$workspace/xcshareddata/xcschemes/AllTests.xcscheme" ui true)" 'ui 범위에서 AllTests 제외'
assert_equal eligible "$(scheme_policy_decide "$projects" "$workspace" "$workspace/xcshareddata/xcschemes/AllTests.xcscheme" all true)" 'build 범위에서는 AllTests도 검증'
assert_equal build "$(scheme_policy_xcode_action build)" 'build action'
assert_equal build "$(scheme_policy_xcode_action build-app)" 'app build action'
assert_equal build-for-testing "$(scheme_policy_xcode_action compile)" 'compile action'
assert_equal build-for-testing "$(scheme_policy_xcode_action compile-unit)" 'unit compile action'
assert_equal test-without-building "$(scheme_policy_xcode_action test)" 'test action'
assert_equal test-without-building "$(scheme_policy_xcode_action test-ui)" 'UI test action'
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

# 읽기 전용 module map만 쓰기 가능으로 되돌리는지 공백·한글·개행 경로로 확인합니다.
. "$module/core/xcodebuild.sh"
module_map_work=$(mktemp -d "${TMPDIR:-/tmp}/project-build-module-map.XXXXXX")
trap 'rm -rf "$module_map_work"' EXIT HUP INT TERM
module_map_derived="$module_map_work/파생 $(printf 'Line\nBreak')"
module_map_modules="$module_map_derived/Build/Products/Debug-iphonesimulator/Promises/FBLPromises.framework/Modules"
mkdir -p "$module_map_modules"
printf 'module FBLPromises {}\n' >"$module_map_modules/module.modulemap"
printf 'other\n' >"$module_map_modules/other.modulemap"
chmod 444 "$module_map_modules/module.modulemap" "$module_map_modules/other.modulemap"
project_xcodebuild_restore_module_maps "$module_map_derived"
[ -w "$module_map_modules/module.modulemap" ] || {
	printf 'FAIL: 읽기 전용 module map 권한을 복구하지 않음\n' >&2
	exit 1
}
[ ! -w "$module_map_modules/other.modulemap" ] || {
	printf 'FAIL: module map 외 파일 권한을 변경함\n' >&2
	exit 1
}
project_xcodebuild_restore_module_maps "$module_map_work/missing" || {
	printf 'FAIL: 빌드 산출물이 없는 DerivedData를 실패로 처리함\n' >&2
	exit 1
}
chmod 644 "$module_map_modules/other.modulemap"
printf 'PASS: project-build core\n'
