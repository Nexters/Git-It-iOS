#!/bin/sh
# shellcheck disable=SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
. "$module/core/measure-policy.sh"

assert_equal() {
	[ "$1" = "$2" ] || {
		printf "FAIL: 기대 '%s', 실제 '%s'\n" "$2" "$1" >&2
		exit 1
	}
}

# 표본 수가 홀수면 가운데 값, 짝수면 가운데 두 값의 평균을 중앙값으로 씁니다.
assert_equal "$(measure_policy_stats '300 100 200')" '3 200 300'
assert_equal "$(measure_policy_stats '400 100 200 300')" '4 250 400'
assert_equal "$(measure_policy_stats '120')" '1 120 120'

# 예산은 gh 호출 수만큼의 시간에 셸 시작 여유 1초를 더합니다.
assert_equal "$(measure_policy_budget 500 3)" 2500
assert_equal "$(measure_policy_budget 500 0)" 1000

# 판정 불일치가 예산보다 먼저이고, 예산 0은 예산이 없다는 뜻입니다.
assert_equal "$(measure_policy_verdict true 900 1000)" ok
assert_equal "$(measure_policy_verdict true 1000 1000)" ok
assert_equal "$(measure_policy_verdict true 1001 1000)" over-budget
assert_equal "$(measure_policy_verdict false 1 1000)" mismatch
assert_equal "$(measure_policy_verdict true 9000 0)" ok
