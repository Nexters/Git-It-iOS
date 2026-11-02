#!/bin/sh
# shellcheck disable=SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
. "$test_dir/fixture.sh"

work=$(mktemp -d "${TMPDIR:-/tmp}/issue-workflow-read-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/저장소 경로"
fake_bin="$work/bin"
fixture_create "$root" "$repository" "$fake_bin"
reader="$repository/.tools/issue-workflow/bin/read-issue.sh"

FAKE_GH_LOG="$work/gh.log"
PATH="$fake_bin:$PATH"
export FAKE_GH_LOG PATH

assert_rejected() {
	assert_code=$1
	shift
	assert_status=0
	"$reader" "$@" >"$work/stdout" 2>"$work/stderr" || assert_status=$?
	[ "$assert_status" -ne 0 ] || {
		printf 'FAIL: %s는 실패해야 합니다\n' "$assert_code" >&2
		exit 1
	}
	grep -q "오류\[issue-workflow\.$assert_code\]" "$work/stderr" || {
		printf 'FAIL: 진단 %s 누락\n' "$assert_code" >&2
		cat "$work/stderr" >&2
		exit 1
	}
	[ ! -s "$work/stdout" ] || {
		printf 'FAIL: %s는 문맥을 출력하면 안 됩니다\n' "$assert_code" >&2
		exit 1
	}
}

# 입력과 브랜치 이름이 틀리면 gh를 부르지 않습니다.
: >"$FAKE_GH_LOG"
assert_rejected invalid-input --branch
assert_rejected invalid-input --unknown value
assert_rejected invalid-branch-name
assert_rejected invalid-branch-name --branch hotfix/crash
assert_rejected invalid-branch-name --branch feature/home-screen
[ ! -s "$FAKE_GH_LOG" ]

# 없거나 닫힌 issue, 확인할 수 없는 상태에서는 문맥을 내지 않습니다.
FAKE_ISSUE_STATE=MISSING
export FAKE_ISSUE_STATE
assert_rejected issue-missing --branch feature/9-ios-home
FAKE_ISSUE_STATE=CLOSED
assert_rejected issue-closed --branch feature/9-ios-home
unset FAKE_ISSUE_STATE

FAKE_GH_FAIL=true
export FAKE_GH_FAIL
assert_rejected issue-state-unavailable --branch feature/9-ios-home
unset FAKE_GH_FAIL

# status: 라벨이 달린 issue는 그 라벨을 알리고 문맥을 내지 않습니다.
FAKE_ISSUE_LABELS='type: tooling
status: on-hold'
export FAKE_ISSUE_LABELS
assert_rejected issue-held --branch feature/9-ios-home
grep -q 'status: on-hold' "$work/stderr"
unset FAKE_ISSUE_LABELS

# 지정한 브랜치의 번호로 제목, 라벨과 본문을 출력합니다.
"$reader" --branch feature/9-ios-home >"$work/stdout"
head -n 1 "$work/stdout" | grep -qx '#9 목적 문장'
grep -qx '## 목적' "$work/stdout"

# 브랜치를 지정하지 않으면 현재 브랜치를 읽습니다.
git -C "$repository" switch -q -c feature/12-project-tool
"$reader" >"$work/stdout"
head -n 1 "$work/stdout" | grep -qx '#12 목적 문장'
