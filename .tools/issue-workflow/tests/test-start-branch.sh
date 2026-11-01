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
	if grep -q 'issue develop' "$FAKE_GH_LOG"; then
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

# 열린 issue에서 issue에 연결된 브랜치를 develop 기준으로 냅니다.
: >"$FAKE_GH_LOG"
"$starter" 9 --domain ios --topic home-screen >"$work/stdout"
grep -q -- '^issue develop 9 --name feature/9-ios-home-screen --base develop --checkout$' "$FAKE_GH_LOG"
tail -n 1 "$work/stdout" | grep -qx 'feature/9-ios-home-screen'
