#!/bin/sh
# shellcheck disable=SC1090,SC1091
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../../../.." && pwd -P)
paths="$root/tools/repository-paths/bin/repository-paths.sh"
hooks_root=$("$paths" GIT_IT_HOOKS_ROOT)
. "$root/$hooks_root/hook-management/core/hook-policy.sh"
. "$root/$hooks_root/hook-management/core/install.sh"

assert_equal() {
	[ "$1" = "$2" ] || {
		printf 'FAIL: %s expected=%s actual=%s\n' "$3" "$1" "$2" >&2
		exit 1
	}
}

assert_equal valid "$(hook_policy_validate_config "$hooks_root" "$hooks_root")" 'local hooksPath'
assert_equal invalid "$(hook_policy_validate_config .git/hooks "$hooks_root")" '잘못된 hooksPath'
assert_equal valid "$(hook_policy_validate_executable true)" 'commit-msg executable'
assert_equal invalid "$(hook_policy_validate_executable false)" '누락 executable'

call_log=/tmp/hook-call-log.$$
: >"$call_log"
fake_set() { printf 'set:%s:%s\n' "$1" "$2" >>"$call_log"; }
fake_prepare() { printf 'prepare:%s:%s\n' "$1" "$2" >>"$call_log"; }
fake_read() {
	printf 'read:%s\n' "$1" >>"$call_log"
	printf '%s\n' "$hooks_root"
}
fake_verify() {
	printf 'verify:%s:%s\n' "$1" "$2" >>"$call_log"
	return 0
}
hook_install_run fake_set fake_prepare fake_read fake_verify /repo "$hooks_root"
assert_equal "set:/repo:$hooks_root
prepare:/repo:$hooks_root
read:/repo
verify:/repo:$hooks_root" "$(cat "$call_log")" '설치 port 순서와 경로 전달'
rm -f "$call_log"
printf 'PASS: hook core\n'
