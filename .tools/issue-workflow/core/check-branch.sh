#!/bin/sh

# 편집 대상, 레인, 브랜치와 issue 상태를 차례로 읽어 편집 허용 여부를 정하는 유스케이스입니다.
# 허용하면 0, 막으면 2, 레인 표를 읽지 못하면 1을 반환합니다.
check_branch_run() (
	check_branch_root=$1
	check_branch_work=$2
	check_branch_file=$3
	check_branch_name_given=$4
	check_branch_name=$5
	check_branch_lane_doc=$6
	check_branch_relative_port=$7
	check_branch_ignored_port=$8
	check_branch_lanes_port=$9
	shift 9
	check_branch_current_port=$1
	check_branch_issue_state_port=$2
	check_branch_report_port=$3

	# 저장소 밖과 Git이 무시하는 파일은 규칙 대상이 아닙니다.
	check_branch_relative=''
	if [ -n "$check_branch_file" ]; then
		check_branch_relative=$("$check_branch_relative_port" "$check_branch_root" "$check_branch_file") || return 0
		if "$check_branch_ignored_port" "$check_branch_relative"; then
			return 0
		fi
	fi

	# 레인 표가 없으면 판정 기준이 없으므로 여기서 멈춥니다.
	check_branch_lanes=$("$check_branch_lanes_port" "$check_branch_lane_doc") || {
		"$check_branch_report_port" missing-lane-table "$check_branch_name" "$check_branch_relative" "$check_branch_lane_doc"
		return 1
	}
	if [ "$check_branch_name_given" = false ]; then
		check_branch_name=$("$check_branch_current_port") || return 1
	fi

	# gh가 실패해도 편집을 멈추지 않도록 상태를 UNKNOWN으로 두고 레인만 검사합니다.
	check_branch_state=''
	check_branch_domains=$(branch_policy_domains "$check_branch_lanes")
	if check_branch_parsed=$(branch_policy_parse "$check_branch_name" "$check_branch_domains"); then
		check_branch_state=$("$check_branch_issue_state_port" "$check_branch_root" "$check_branch_name" \
			"${check_branch_parsed%% *}" "$check_branch_work") || {
			"$check_branch_report_port" issue-state-unavailable "$check_branch_name" "$check_branch_relative" "$check_branch_lane_doc"
			check_branch_state=UNKNOWN
		}
	fi

	check_branch_verdict=$(branch_policy_decide "$check_branch_name" "$check_branch_lanes" \
		"$check_branch_state" "$check_branch_relative")
	[ "$check_branch_verdict" != allow ] || return 0
	"$check_branch_report_port" "$check_branch_verdict" "$check_branch_name" "$check_branch_relative" "$check_branch_lane_doc"
	return 2
)
