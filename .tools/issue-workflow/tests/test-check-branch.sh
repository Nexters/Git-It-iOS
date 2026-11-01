#!/bin/sh
# shellcheck disable=SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
. "$test_dir/fixture.sh"
ios_root=$("$root/.tools/repository-paths/bin/repository-paths.sh" GIT_IT_IOS_ROOT)

work=$(mktemp -d "${TMPDIR:-/tmp}/issue-workflow-check-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
# 저장소 경로에 공백과 한글이 있어도 동작해야 합니다.
repository="$work/저장소 경로"
fake_bin="$work/bin"
mkdir -p "$work/tmp"
fixture_create "$root" "$repository" "$fake_bin"
checker="$repository/.tools/issue-workflow/bin/check-branch.sh"

FAKE_GH_LOG="$work/gh.log"
TMPDIR="$work/tmp"
PATH="$fake_bin:$PATH"
export FAKE_GH_LOG TMPDIR PATH
: >"$FAKE_GH_LOG"

reset_cache() {
	rm -rf "$work/tmp/git-it-issue-workflow"
	: >"$FAKE_GH_LOG"
}

# hook 입력과 같은 JSON을 stdin으로 넘깁니다.
run_hook() {
	printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1" |
		"$checker" >"$work/stdout" 2>"$work/stderr"
}

assert_allowed() {
	if ! run_hook "$1"; then
		printf 'FAIL: %s는 허용되어야 합니다\n' "$1" >&2
		cat "$work/stderr" >&2
		exit 1
	fi
}

assert_blocked() {
	assert_status=0
	run_hook "$1" || assert_status=$?
	[ "$assert_status" -eq 2 ] || {
		printf 'FAIL: %s는 exit 2로 막혀야 합니다(실제 %s)\n' "$1" "$assert_status" >&2
		exit 1
	}
	grep -q "오류\[issue-workflow\.$2\]" "$work/stderr" || {
		printf 'FAIL: 진단 %s 누락\n' "$2" >&2
		cat "$work/stderr" >&2
		exit 1
	}
}

# 보호 브랜치는 막고, 저장소 밖과 Git이 무시하는 파일은 통과시킵니다.
assert_blocked "$repository/$ios_root/App.swift" protected-branch
assert_blocked "$repository/docs/new.md" protected-branch
assert_allowed "$repository/ignored.txt"
assert_allowed "$work/outside.txt"

# 이름 형식이 틀린 브랜치를 막습니다.
git -C "$repository" switch -q -c feature/home-screen
assert_blocked "$repository/$ios_root/App.swift" invalid-branch-name

# 열린 issue의 ios 브랜치는 자기 레인과 레인 없는 경로만 고칩니다.
git -C "$repository" switch -q -c feature/9-ios-home
assert_allowed "$repository/$ios_root/App.swift"
assert_allowed "$repository/$ios_root/새 폴더/New.swift"
assert_allowed "$repository/docs/new.md"
assert_blocked "$repository/AGENTS.md" lane-mismatch

# 심볼릭 링크는 원본 경로의 레인으로 판정합니다.
assert_blocked "$repository/CLAUDE.md" lane-mismatch
assert_blocked "$repository/.claude/skills/new/SKILL.md" lane-mismatch
grep -q "'.agents/skills/new/SKILL.md'" "$work/stderr"

# project 브랜치는 iOS 앱 경로를 고칠 수 없습니다.
git -C "$repository" switch -q -c feature/9-project-tool
reset_cache
assert_allowed "$repository/AGENTS.md"
assert_blocked "$repository/$ios_root/App.swift" lane-mismatch

# issue 상태를 한 번만 조회하고 재사용합니다.
reset_cache
assert_allowed "$repository/AGENTS.md"
assert_allowed "$repository/AGENTS.md"
[ "$(wc -l <"$FAKE_GH_LOG" | tr -d ' ')" -eq 1 ]

# 닫혔거나 없는 issue의 브랜치를 막습니다.
reset_cache
FAKE_ISSUE_STATE=CLOSED
export FAKE_ISSUE_STATE
assert_blocked "$repository/AGENTS.md" issue-closed
reset_cache
FAKE_ISSUE_STATE=MISSING
assert_blocked "$repository/AGENTS.md" issue-missing
unset FAKE_ISSUE_STATE

# PR 번호는 열려 있어도 issue가 아니므로 막습니다.
reset_cache
FAKE_ISSUE_KIND=pull
export FAKE_ISSUE_KIND
assert_blocked "$repository/AGENTS.md" issue-missing
unset FAKE_ISSUE_KIND

# gh가 실패하면 막지 않지만 레인 위반은 그대로 막습니다.
reset_cache
FAKE_GH_FAIL=true
export FAKE_GH_FAIL
assert_allowed "$repository/AGENTS.md"
grep -q 'issue-workflow.issue-state-unavailable' "$work/stderr"
reset_cache
assert_blocked "$repository/$ios_root/App.swift" lane-mismatch
unset FAKE_GH_FAIL

# gh가 없어도 issue가 없다고 판정해 막지 않습니다.
reset_cache
original_path=$PATH
PATH=/usr/bin:/bin
export PATH
if command -v gh >/dev/null 2>&1; then
	PATH=$original_path
	export PATH
	printf 'gh가 시스템 경로에 있어 미설치 검증을 건너뜁니다\n'
else
	assert_allowed "$repository/AGENTS.md"
	grep -q 'issue-workflow.issue-state-unavailable' "$work/stderr"
	PATH=$original_path
	export PATH
fi

# Git-flow 브랜치는 issue 없이 통과합니다.
reset_cache
git -C "$repository" switch -q -c hotfix/crash
assert_allowed "$repository/$ios_root/App.swift"
assert_allowed "$repository/AGENTS.md"
git -C "$repository" switch -q -c release/v1.2.3
assert_allowed "$repository/AGENTS.md"
[ ! -s "$FAKE_GH_LOG" ]

# detached HEAD는 브랜치가 아니므로 막습니다.
git -C "$repository" switch -q --detach
assert_blocked "$repository/docs/new.md" detached-head

# 손으로 돌릴 때는 인자로 브랜치와 파일을 줍니다.
"$checker" --branch feature/9-ios-home --file "$ios_root/App.swift"
status=0
"$checker" --branch develop --file "$ios_root/App.swift" 2>/dev/null || status=$?
[ "$status" -eq 2 ]

# 입력 오류는 stderr 진단과 함께 실패합니다.
status=0
"$checker" --unknown 2>"$work/stderr" || status=$?
[ "$status" -eq 2 ]
grep -q 'issue-workflow.invalid-input' "$work/stderr"

# 다른 작업 폴더에서 호출해도 저장소 기준으로 판정합니다.
git -C "$repository" switch -q feature/9-ios-home
reset_cache
(cd "$work" && assert_allowed "$repository/$ios_root/App.swift")

# 디스크 이름이 NFD인 저장소를 NFC 작업 폴더에서 상대 경로로 호출해도 저장소 안 파일로 판정합니다.
nfd_repository="$work/$(printf '\341\204\200\341\205\241')"
nfc_repository="$work/$(printf '\352\260\200')"
fixture_create "$root" "$nfd_repository" "$work/normalization-bin"
if [ -d "$nfc_repository" ]; then
	status=0
	(cd "$nfc_repository" && ./.tools/issue-workflow/bin/check-branch.sh --branch develop --file "$ios_root/App.swift") \
		2>"$work/stderr" || status=$?
	[ "$status" -eq 2 ] || {
		printf 'FAIL: 정규화가 다른 경로의 저장소 파일을 저장소 밖으로 판정했습니다(실제 %s)\n' "$status" >&2
		exit 1
	}
	grep -q 'issue-workflow.protected-branch' "$work/stderr"
else
	printf '파일 시스템이 정규화를 구분해 NFC/NFD 검증을 건너뜁니다\n'
fi
