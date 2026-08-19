#!/bin/sh
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
classifier="$module/bin/classify-changes.sh"
paths="$root/tools/repository-paths/bin/repository-paths.sh"
ios_relative=$("$paths" GIT_IT_IOS_ROOT)
projects_relative=$("$paths" GIT_IT_PROJECTS_ROOT)
work=$(mktemp -d "${TMPDIR:-/tmp}/ci-classify-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/저장소"
output="$work/output"
summary="$work/summary"

assert_flag() {
	assert_key=$1
	assert_value=$2
	rg -q "^${assert_key}=${assert_value}$" "$output" || {
		printf 'FAIL: %s=%s 출력 누락\n' "$assert_key" "$assert_value" >&2
		cat "$output" >&2
		exit 1
	}
}

run_classifier() {
	run_base=$1
	run_head=$2
	: >"$output"
	: >"$summary"
	(
		cd "$repository"
		GITHUB_OUTPUT="$output" GITHUB_STEP_SUMMARY="$summary" \
			"$classifier" "$run_base" "$run_head" >"$work/stdout"
	)
}

# 실제 PR과 같은 base-head commit 범위를 가진 격리 저장소를 만듭니다.
mkdir -p "$repository"
git -C "$repository" init -q
git -C "$repository" config user.name ci-reviewer
git -C "$repository" config user.email ci-reviewer@example.com
printf '# Fixture\n' >"$repository/README.md"
git -C "$repository" add -- README.md
git -C "$repository" commit -qm base

# 문서 전용 변경은 macOS job 플래그를 활성화하지 않습니다.
docs_base=$(git -C "$repository" rev-parse HEAD)
printf '\n문서 변경\n' >>"$repository/README.md"
git -C "$repository" add -- README.md
git -C "$repository" commit -qm docs
docs_head=$(git -C "$repository" rev-parse HEAD)
run_classifier "$docs_base" "$docs_head"
assert_flag docs_only true
assert_flag swift_changed false
assert_flag ui_changed false
assert_flag build_required false
assert_flag unit_tests_required false
assert_flag ui_tests_required false

# 한글 Swift 경로와 개행을 포함한 App 입력도 NUL 경계를 보존해 분류합니다.
source_base=$docs_head
newline_name=$(printf '줄\n바꿈.entitlements')
mkdir -p "$repository/$ios_relative/프로젝트" "$repository/$projects_relative/App"
printf 'struct 화면 {}\n' >"$repository/$ios_relative/프로젝트/화면.swift"
printf 'fixture\n' >"$repository/$projects_relative/App/$newline_name"
git -C "$repository" add -- .
git -C "$repository" commit -qm source
source_head=$(git -C "$repository" rev-parse HEAD)
run_classifier "$source_base" "$source_head"
assert_flag docs_only false
assert_flag swift_changed true
assert_flag tests_changed true
assert_flag build_required true
assert_flag unit_tests_required true
assert_flag ui_tests_required false
rg -q '\*\*변경 파일 수\*\*: 2$' "$summary"

# UI 리소스는 Swift 파일이 아니어도 앱·단위·UI 검사를 모두 활성화합니다.
ui_base=$source_head
asset_directory=$(printf 'Re\163ources')
mkdir -p "$repository/$projects_relative/UI/Component/$asset_directory"
printf 'fixture\n' >"$repository/$projects_relative/UI/Component/$asset_directory/Icon.png"
git -C "$repository" add -- .
git -C "$repository" commit -qm ui-resource
ui_head=$(git -C "$repository" rev-parse HEAD)
run_classifier "$ui_base" "$ui_head"
assert_flag swift_changed true
assert_flag tests_changed true
assert_flag ui_changed true
assert_flag build_required true
assert_flag unit_tests_required true
assert_flag ui_tests_required true

# 알려지지 않은 비문서 입력은 검사를 생략하지 않고 보수적으로 승격합니다.
unknown_base=$ui_head
mkdir -p "$repository/configuration"
printf 'fixture=true\n' >"$repository/configuration/custom.conf"
git -C "$repository" add -- .
git -C "$repository" commit -qm unknown
unknown_head=$(git -C "$repository" rev-parse HEAD)
run_classifier "$unknown_base" "$unknown_head"
assert_flag docs_only false
assert_flag swift_changed true
assert_flag tests_changed true
assert_flag build_required true
assert_flag unit_tests_required true

# 접근할 수 없는 base는 성공으로 오인하지 않습니다.
if (
	cd "$repository"
	"$classifier" 0000000000000000000000000000000000000000 "$unknown_head" \
		>"$work/invalid-out" 2>"$work/invalid-err"
); then
	printf 'FAIL: 접근할 수 없는 base를 성공으로 반환\n' >&2
	exit 1
else
	result=$?
fi
[ "$result" -eq 1 ]
rg -q 'ci.classify-changes.base-unreachable' "$work/invalid-err"

printf 'PASS: CI change classifier\n'
