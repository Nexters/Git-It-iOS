#!/bin/sh

# 브랜치의 issue를 확인하고 Spec Kit 단계가 읽을 문맥을 출력하는 유스케이스입니다.
# 규칙 위반은 2, 레인 표나 issue를 읽지 못하면 1을 반환합니다.
read_issue_run() (
	read_issue_name_given=$1
	read_issue_name=$2
	read_issue_lane_doc=$3
	read_issue_work=$4
	read_issue_lanes_port=$5
	read_issue_current_port=$6
	read_issue_state_port=$7
	read_issue_labels_port=$8
	read_issue_context_port=$9
	shift 9
	read_issue_report_port=$1

	# 도메인 목록이 있어야 브랜치 이름을 해석할 수 있습니다.
	read_issue_lanes=$("$read_issue_lanes_port" "$read_issue_lane_doc") || {
		"$read_issue_report_port" missing-lane-table "$read_issue_lane_doc"
		return 1
	}
	if [ "$read_issue_name_given" = false ]; then
		read_issue_name=$("$read_issue_current_port") || return 1
	fi

	# issue 번호는 브랜치 이름에서 얻습니다.
	read_issue_domains=$(branch_policy_domains "$read_issue_lanes")
	read_issue_parsed=$(branch_policy_parse "$read_issue_name" "$read_issue_domains") || {
		"$read_issue_report_port" invalid-branch-name "$read_issue_name"
		return 2
	}
	read_issue_number=${read_issue_parsed%% *}

	# 시작할 수 없는 issue의 문맥은 내지 않습니다.
	issue_gate_check "$read_issue_number" "$read_issue_work" "$read_issue_state_port" \
		"$read_issue_labels_port" "$read_issue_report_port" || return $?

	"$read_issue_context_port" "$read_issue_number" || {
		"$read_issue_report_port" issue-state-unavailable "$read_issue_number"
		return 1
	}
)
