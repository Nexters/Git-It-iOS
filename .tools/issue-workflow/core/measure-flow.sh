#!/bin/sh

# 명령을 반복 실행해 판정과 소요 시간을 표의 한 행으로 출력하는 유스케이스입니다.
# 판정이 기대와 다르거나 중앙값이 예산을 넘으면 1을 반환합니다.
measure_flow_sample() (
	measure_flow_label=$1
	measure_flow_status_wanted=$2
	measure_flow_code_wanted=$3
	measure_flow_repeat=$4
	measure_flow_budget=$5
	measure_flow_work=$6
	measure_flow_clock_port=$7
	measure_flow_report_port=$8
	shift 8

	# 판정이 어긋나면 더 반복하지 않습니다.
	measure_flow_samples=''
	measure_flow_matched=true
	measure_flow_round=0
	while [ "$measure_flow_round" -lt "$measure_flow_repeat" ] && [ "$measure_flow_matched" = true ]; do
		measure_flow_round=$((measure_flow_round + 1))

		# 명령 한 번의 벽시계 시간을 잽니다.
		measure_flow_start=$("$measure_flow_clock_port")
		measure_flow_status=0
		"$@" >/dev/null 2>"$measure_flow_work/sample-error" || measure_flow_status=$?
		measure_flow_end=$("$measure_flow_clock_port")
		measure_flow_samples="$measure_flow_samples $((measure_flow_end - measure_flow_start))"

		# 종료 코드와 진단 코드가 모두 기대와 같아야 합니다.
		[ "$measure_flow_status" -eq "$measure_flow_status_wanted" ] || measure_flow_matched=false
		if [ -n "$measure_flow_code_wanted" ] &&
			! grep -q "오류\[issue-workflow\.$measure_flow_code_wanted\]" "$measure_flow_work/sample-error"; then
			measure_flow_matched=false
		fi
	done

	# 표본을 "개수 중앙값 최댓값"으로 줄입니다.
	measure_flow_stats=$(measure_policy_stats "$measure_flow_samples")
	measure_flow_count=${measure_flow_stats%% *}
	measure_flow_rest=${measure_flow_stats#* }
	measure_flow_median=${measure_flow_rest%% *}
	measure_flow_max=${measure_flow_rest#* }
	printf '%s\n' "$measure_flow_median" >"$measure_flow_work/sample-median"

	measure_flow_wanted="exit $measure_flow_status_wanted"
	[ -z "$measure_flow_code_wanted" ] || measure_flow_wanted="$measure_flow_wanted $measure_flow_code_wanted"

	# 판정을 표의 결과 칸과 진단으로 옮깁니다.
	measure_flow_failed=false
	case "$(measure_policy_verdict "$measure_flow_matched" "$measure_flow_median" "$measure_flow_budget")" in
	ok)
		measure_flow_result=통과
		;;
	mismatch)
		measure_flow_result='판정 불일치'
		measure_flow_failed=true
		"$measure_flow_report_port" measure-mismatch "$measure_flow_label" "$measure_flow_status" \
			"$measure_flow_wanted" "$measure_flow_work/sample-error"
		;;
	*)
		measure_flow_result='예산 초과'
		measure_flow_failed=true
		"$measure_flow_report_port" measure-over-budget "$measure_flow_label" "$measure_flow_median" "$measure_flow_budget"
		;;
	esac

	measure_flow_budget_cell=$measure_flow_budget
	[ "$measure_flow_budget" -gt 0 ] || measure_flow_budget_cell=-
	printf '| %s | %s | %s | %s | %s | %s | %s |\n' "$measure_flow_label" "$measure_flow_wanted" "$measure_flow_result" \
		"$measure_flow_count" "$measure_flow_median" "$measure_flow_max" "$measure_flow_budget_cell"
	[ "$measure_flow_failed" = false ]
)
