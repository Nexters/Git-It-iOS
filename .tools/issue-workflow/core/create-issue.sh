#!/bin/sh

# 제목과 라벨을 정책으로 검사하고 본문을 준비해 issue를 만드는 유스케이스입니다.
# 규칙 위반은 2, 라벨 표를 읽지 못하면 1을 반환합니다.
create_issue_run() (
	create_issue_title=$1
	create_issue_title_limit=$2
	create_issue_labels=$3
	create_issue_template_file=$4
	create_issue_body_file=$5
	create_issue_label_doc=$6
	create_issue_work=$7
	create_issue_known_port=$8
	create_issue_template_labels_port=$9
	shift 9
	create_issue_template_body_port=$1
	create_issue_fill_purpose_port=$2
	create_issue_create_port=$3
	create_issue_report_port=$4

	# 제목은 목적 한 문장이며 글자 수는 공백을 포함해 셉니다.
	create_issue_length=$(issue_policy_title_length "$create_issue_title")
	[ "$create_issue_length" -le "$create_issue_title_limit" ] || {
		"$create_issue_report_port" title-too-long "$create_issue_length" "$create_issue_title_limit"
		return 2
	}

	# 템플릿 기본 라벨과 입력 라벨을 합쳐 라벨 표로 검사합니다.
	create_issue_known=$("$create_issue_known_port" "$create_issue_label_doc") || {
		"$create_issue_report_port" missing-label-table "$create_issue_label_doc"
		return 1
	}
	create_issue_template_labels=$("$create_issue_template_labels_port" "$create_issue_template_file") || return $?
	create_issue_selected=$(issue_policy_unique_labels "$create_issue_template_labels
$create_issue_labels")
	create_issue_check=$(issue_policy_check_labels "$create_issue_known" "$create_issue_selected")
	[ "$create_issue_check" = ok ] || {
		"$create_issue_report_port" "$create_issue_check" "$create_issue_label_doc"
		return 2
	}

	# 본문 파일이 없으면 템플릿 본문의 목적 절을 제목으로 채웁니다.
	create_issue_body=$create_issue_body_file
	if [ -z "$create_issue_body" ]; then
		create_issue_body="$create_issue_work/body.md"
		"$create_issue_template_body_port" "$create_issue_template_file" >"$create_issue_work/template.md" || return $?
		"$create_issue_fill_purpose_port" "$create_issue_work/template.md" "$create_issue_title" >"$create_issue_body" || return $?
	fi

	"$create_issue_create_port" "$create_issue_title" "$create_issue_body" "$create_issue_selected"
)
