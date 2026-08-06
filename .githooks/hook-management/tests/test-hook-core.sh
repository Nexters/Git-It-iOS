#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd -P)
. "$root/.githooks/hook-management/core/hook-policy.sh"
. "$root/.githooks/hook-management/core/install.sh"

assert_equal() {
	[ "$1" = "$2" ] || {
		printf 'FAIL: %s expected=%s actual=%s\n' "$3" "$1" "$2" >&2
		exit 1
	}
}

assert_equal valid "$(hook_policy_validate_config .githooks .githooks)" 'local hooksPath'
assert_equal invalid "$(hook_policy_validate_config .git/hooks .githooks)" '잘못된 hooksPath'
assert_equal valid "$(hook_policy_validate_executable true)" 'commit-msg executable'
assert_equal invalid "$(hook_policy_validate_executable false)" '누락 executable'

call_log=/tmp/hook-call-log.$$
: >"$call_log"
fake_set() { printf 'set\n' >>"$call_log"; }
fake_prepare() { printf 'prepare\n' >>"$call_log"; }
fake_read() {
	printf 'read\n' >>"$call_log"
	printf '.githooks\n'
}
fake_verify() {
	printf 'verify\n' >>"$call_log"
	return 0
}
hook_install_run fake_set fake_prepare fake_read fake_verify
assert_equal 'set
prepare
read
verify' "$(cat "$call_log")" '설치 port 순서'
rm -f "$call_log"
printf 'PASS: hook core\n'
