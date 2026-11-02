#!/bin/sh
# shellcheck disable=SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
. "$test_dir/fixture.sh"

work=$(mktemp -d "${TMPDIR:-/tmp}/issue-workflow-start-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/저장소 경로"
fake_bin="$work/bin"
fixture_create "$root" "$repository" "$fake_bin"
starter="$repository/.tools/issue-workflow/bin/start-branch.sh"

FAKE_GH_LOG="$work/gh.log"
PATH="$fake_bin:$PATH"
export FAKE_GH_LOG PATH

assert_rejected() {
	assert_code=$1
	shift
	: >"$FAKE_GH_LOG"
	assert_status=0
	"$starter" "$@" 2>"$work/stderr" || assert_status=$?
	[ "$assert_status" -ne 0 ] || {
		printf 'FAIL: %s는 실패해야 합니다\n' "$assert_code" >&2
		exit 1
	}
	grep -q "오류\[issue-workflow\.$assert_code\]" "$work/stderr" || {
		printf 'FAIL: 진단 %s 누락\n' "$assert_code" >&2
		cat "$work/stderr" >&2
		exit 1
	}
	if grep -q 'issue develop .*--name' "$FAKE_GH_LOG"; then
		printf 'FAIL: 검사 실패 시 브랜치를 내면 안 됩니다\n' >&2
		exit 1
	fi
}

# 입력은 gh 조회 전에 거부합니다.
assert_rejected invalid-issue-number --domain ios --topic home
assert_rejected invalid-issue-number 0 --domain ios --topic home
assert_rejected invalid-issue-number x9 --domain ios --topic home
assert_rejected unknown-domain 9 --domain sample --topic home
assert_rejected unknown-domain 9 --topic home
assert_rejected invalid-topic 9 --domain ios --topic Home
assert_rejected invalid-topic 9 --domain ios
assert_rejected invalid-input 9 --domain
assert_rejected invalid-input 9 --unknown value
[ ! -s "$FAKE_GH_LOG" ]

# 없거나 닫힌 issue, 확인할 수 없는 상태에서는 브랜치를 내지 않습니다.
FAKE_ISSUE_STATE=MISSING
export FAKE_ISSUE_STATE
assert_rejected issue-missing 9 --domain ios --topic home
FAKE_ISSUE_STATE=CLOSED
assert_rejected issue-closed 9 --domain ios --topic home
unset FAKE_ISSUE_STATE

# PR 번호는 열려 있어도 issue가 아니므로 브랜치를 내지 않습니다.
FAKE_ISSUE_KIND=pull
export FAKE_ISSUE_KIND
assert_rejected issue-missing 9 --domain ios --topic home
unset FAKE_ISSUE_KIND

FAKE_GH_FAIL=true
export FAKE_GH_FAIL
assert_rejected issue-state-unavailable 9 --domain ios --topic home
unset FAKE_GH_FAIL

# status: 라벨이 달린 issue에서는 그 라벨을 알리고 브랜치를 내지 않습니다.
FAKE_ISSUE_LABELS='type: tooling
status: blocked'
export FAKE_ISSUE_LABELS
assert_rejected issue-held 9 --domain ios --topic home
grep -q 'status: blocked' "$work/stderr"
unset FAKE_ISSUE_LABELS

# 같은 레인의 브랜치가 남아 있으면 그 브랜치를 알리고 브랜치를 내지 않습니다.
# PR을 연 브랜치는 issue의 연결 목록에서 빠지므로 번호로 시작하는 브랜치를 찾습니다.
FAKE_ISSUE_BRANCHES='feature/9-ios-other'
export FAKE_ISSUE_BRANCHES
assert_rejected issue-in-progress 9 --domain ios --topic home
grep -q 'feature/9-ios-other' "$work/stderr"
grep -q 'git/matching-refs/heads/feature/9-' "$FAKE_GH_LOG"
if grep -q 'issue develop' "$FAKE_GH_LOG"; then
	printf 'FAIL: 연결 목록에 기대면 PR을 연 브랜치를 놓칩니다\n' >&2
	exit 1
fi

# --check도 같은 기준으로 막습니다.
assert_rejected issue-in-progress 9 --domain ios --topic home --check

# 다른 레인의 브랜치는 경로가 겹치지 않으므로 막지 않습니다.
: >"$FAKE_GH_LOG"
"$starter" 9 --domain project --topic home >"$work/stdout"
grep -q -- '^issue develop 9 --name feature/9-project-home --base develop --checkout$' "$FAKE_GH_LOG"
unset FAKE_ISSUE_BRANCHES

# 라벨이나 브랜치 목록을 읽지 못하면 상태를 모르므로 브랜치를 내지 않습니다.
FAKE_LABELS_FAIL=true
export FAKE_LABELS_FAIL
assert_rejected issue-state-unavailable 9 --domain ios --topic home
unset FAKE_LABELS_FAIL
FAKE_BRANCHES_FAIL=true
export FAKE_BRANCHES_FAIL
assert_rejected issue-state-unavailable 9 --domain ios --topic home
unset FAKE_BRANCHES_FAIL

# 열린 issue에서 issue에 연결된 브랜치를 develop 기준으로 냅니다.
: >"$FAKE_GH_LOG"
"$starter" 9 --domain ios --topic home-screen >"$work/stdout"
grep -q -- '^issue develop 9 --name feature/9-ios-home-screen --base develop --checkout$' "$FAKE_GH_LOG"
tail -n 1 "$work/stdout" | grep -qx 'feature/9-ios-home-screen'

# --check는 판정만 하고 브랜치를 내지 않습니다.
: >"$FAKE_GH_LOG"
"$starter" 9 --domain ios --topic home --check >"$work/stdout"
tail -n 1 "$work/stdout" | grep -qx 'feature/9-ios-home'
if grep -q 'issue develop' "$FAKE_GH_LOG"; then
	printf 'FAIL: --check는 브랜치를 내면 안 됩니다\n' >&2
	exit 1
fi
