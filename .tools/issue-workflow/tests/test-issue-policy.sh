#!/bin/sh
# shellcheck disable=SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
. "$module/core/issue-policy.sh"

tab=$(printf '\t')
known="type:${tab}type: bug${tab}required
type:${tab}type: chore${tab}required
priority:${tab}priority: low${tab}required
priority:${tab}priority: high${tab}required
status:${tab}status: blocked${tab}optional"

assert_equal() {
	[ "$1" = "$2" ] || {
		printf 'FAIL: 기대 %s, 실제 %s\n' "$2" "$1" >&2
		exit 1
	}
}

# 한글과 공백도 locale과 무관하게 한 글자로 셉니다.
assert_equal "$(issue_policy_title_length '가나다 abc')" 7
assert_equal "$(LC_ALL=C issue_policy_title_length '가나다 abc')" 7
assert_equal "$(issue_policy_title_length '')" 0

# 빈 줄과 중복을 지우고 순서를 유지합니다.
assert_equal "$(issue_policy_unique_labels 'type: bug

priority: low
type: bug')" 'type: bug
priority: low'

# 라벨 조합 판정
assert_equal "$(issue_policy_check_labels "$known" 'type: bug
priority: low')" ok
assert_equal "$(issue_policy_check_labels "$known" 'type: bug
priority: low
status: blocked')" ok
assert_equal "$(issue_policy_check_labels "$known" 'type: bug
없는 라벨')" 'unknown:없는 라벨'
assert_equal "$(issue_policy_check_labels "$known" 'type: bug
type: chore
priority: low')" duplicate:type:
assert_equal "$(issue_policy_check_labels "$known" 'type: bug')" missing:priority:
assert_equal "$(issue_policy_check_labels "$known" '')" missing:type:
