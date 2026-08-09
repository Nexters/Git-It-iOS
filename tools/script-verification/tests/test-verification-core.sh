#!/bin/sh
# shellcheck disable=SC1091
set -eu

suite=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
. "$suite/core/verification-policy.sh"
. "$suite/core/prepare-tools.sh"
. "$suite/core/verify.sh"

assert_equal() {
	[ "$1" = "$2" ] || {
		printf 'FAIL: %s expected=%s actual=%s\n' "$3" "$1" "$2" >&2
		exit 1
	}
}

assert_equal succeeded "$(verification_policy_aggregate 5 0)" '전체 성공'
assert_equal failed "$(verification_policy_aggregate 5 2)" 'fail-after-collect'
call_log=/tmp/verification-call-log.$$
: >"$call_log"
fake_lock() { printf 'lock\n' >>"$call_log"; }
fake_fetch() { printf 'fetch\n' >>"$call_log"; }
fake_integrity() { printf 'integrity\n' >>"$call_log"; }
fake_place() { printf 'place\n' >>"$call_log"; }
prepare_tools_run fake_lock fake_fetch fake_integrity fake_place
assert_equal 'lock
fetch
integrity
place' "$(cat "$call_log")" '명시적 준비 흐름'

: >"$call_log"
fake_dependency() {
	printf 'dependency\n' >>"$call_log"
	return 1
}
fake_static() {
	printf 'static\n' >>"$call_log"
	return 0
}
fake_regression() {
	printf 'regression\n' >>"$call_log"
	return 1
}
fake_checklist() {
	printf 'checklist\n' >>"$call_log"
	return 0
}
if verify_run fake_dependency fake_static fake_regression fake_checklist; then
	printf 'FAIL: 검증 실패 집계가 성공함\n' >&2
	exit 1
fi
assert_equal 'dependency
static
regression
checklist' "$(cat "$call_log")" 'fail-after-collect 흐름'
rm -f "$call_log"
printf 'PASS: verification core\n'
