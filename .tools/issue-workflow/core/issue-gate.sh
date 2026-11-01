#!/bin/sh

# 작업을 시작할 수 있는 issue인지 확인하는 유스케이스 공용 검사입니다.
# 규칙 위반은 2, issue 상태를 읽지 못하면 1을 반환합니다.
issue_gate_check() (
	issue_gate_number=$1
	issue_gate_work=$2
	issue_gate_state_port=$3
	issue_gate_labels_port=$4
	issue_gate_report_port=$5

	# 열린 issue만 시작할 수 있습니다.
	issue_gate_state=$("$issue_gate_state_port" "$issue_gate_number" "$issue_gate_work") || {
		"$issue_gate_report_port" issue-state-unavailable "$issue_gate_number"
		return 1
	}
	case "$issue_gate_state" in
	OPEN) ;;
	MISSING)
		"$issue_gate_report_port" issue-missing "$issue_gate_number"
		return 2
		;;
	*)
		"$issue_gate_report_port" issue-closed "$issue_gate_number"
		return 2
		;;
	esac

	# status: 라벨이 달린 issue는 지금 시작하지 않습니다.
	issue_gate_labels=$("$issue_gate_labels_port" "$issue_gate_number") || {
		"$issue_gate_report_port" issue-state-unavailable "$issue_gate_number"
		return 1
	}
	issue_gate_hold=$(issue_policy_hold_label "$issue_gate_labels")
	[ -z "$issue_gate_hold" ] || {
		"$issue_gate_report_port" issue-held "$issue_gate_number" "$issue_gate_hold"
		return 2
	}
)
