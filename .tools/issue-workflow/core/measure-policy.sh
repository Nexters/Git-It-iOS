#!/bin/sh
# 측정 표본을 요약하고 예산을 판정하는 순수 정책입니다.

# 밀리초 표본 목록을 "개수 중앙값 최댓값"으로 출력합니다.
measure_policy_stats() (
	for measure_policy_sample in $1; do
		printf '%s\n' "$measure_policy_sample"
	done | sort -n | awk '
		{ sample[NR] = $1 }
		END {
			middle = int((NR + 1) / 2)
			median = (NR % 2) ? sample[middle] : int((sample[middle] + sample[middle + 1]) / 2)
			print NR, median, sample[NR]
		}
	'
)

# gh 호출 수만큼의 시간에 셸 시작 여유 1초를 더한 예산을 출력합니다.
measure_policy_budget() (
	printf '%s\n' "$(($1 * $2 + 1000))"
)

# 판정이 기대와 같은지 본 뒤 중앙값이 예산 안인지 봅니다. 예산 0은 예산이 없다는 뜻입니다.
measure_policy_verdict() (
	[ "$1" = true ] || {
		printf 'mismatch\n'
		return 0
	}
	if [ "$3" -gt 0 ] && [ "$2" -gt "$3" ]; then
		printf 'over-budget\n'
	else
		printf 'ok\n'
	fi
)
