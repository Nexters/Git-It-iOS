#!/bin/sh

# 도메인, 내용과 issue 상태를 검사하고 시작할 수 있는 issue에서 브랜치를 내는 유스케이스입니다.
# 규칙 위반은 2, 레인 표나 issue 상태를 읽지 못하면 1을 반환합니다.
start_branch_run() (
	start_branch_number=$1
	start_branch_domain=$2
	start_branch_topic=$3
	start_branch_lane_doc=$4
	start_branch_work=$5
	start_branch_lanes_port=$6
	start_branch_issue_state_port=$7
	start_branch_labels_port=$8
	start_branch_branches_port=$9
	shift 9
	start_branch_develop_port=$1
	start_branch_report_port=$2

	# 도메인은 레인 표의 값만 받습니다.
	start_branch_lanes=$("$start_branch_lanes_port" "$start_branch_lane_doc") || {
		"$start_branch_report_port" missing-lane-table "$start_branch_lane_doc"
		return 1
	}
	start_branch_domains=$(branch_policy_domains "$start_branch_lanes")
	branch_policy_has_domain "$start_branch_domain" "$start_branch_domains" || {
		"$start_branch_report_port" unknown-domain "$start_branch_domain" "$start_branch_domains"
		return 2
	}
	branch_policy_is_topic "$start_branch_topic" || {
		"$start_branch_report_port" invalid-topic "$start_branch_topic"
		return 2
	}

	# 없거나 닫혔거나 status: 라벨이 달린 issue에서는 브랜치를 내지 않습니다.
	issue_gate_check "$start_branch_number" "$start_branch_work" "$start_branch_issue_state_port" \
		"$start_branch_labels_port" "$start_branch_report_port" || return $?

	# 같은 레인의 브랜치가 남아 있으면 같은 일을 두 번 시작하는 것이므로 막습니다.
	start_branch_branches=$("$start_branch_branches_port" "$start_branch_number") || {
		"$start_branch_report_port" issue-state-unavailable "$start_branch_number"
		return 1
	}
	start_branch_active=$(branch_policy_active_branch "$start_branch_branches" "$start_branch_domain" "$start_branch_domains")
	[ -z "$start_branch_active" ] || {
		"$start_branch_report_port" issue-in-progress "$start_branch_number" "$start_branch_active"
		return 2
	}

	start_branch_name="feature/$start_branch_number-$start_branch_domain-$start_branch_topic"
	"$start_branch_develop_port" "$start_branch_number" "$start_branch_name" || return $?
	printf '%s\n' "$start_branch_name"
)
