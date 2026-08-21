#!/bin/sh
# 초기화 동작별 사전 검사와 파일 변경 순서를 조합합니다.

project_setup_workspace_links() (
	project_setup_root=$1
	project_setup_target=$2
	project_setup_link=$3
	project_setup_edit_target=$4
	project_setup_edit_link=$5
	project_setup_preflight_port=$6
	project_setup_replace_port=$7

	# 두 위치의 충돌을 모두 확인한 뒤 workspace 링크를 함께 갱신합니다.
	"$project_setup_preflight_port" "$project_setup_root" \
		"$project_setup_target" "$project_setup_link" || return $?
	"$project_setup_preflight_port" "$project_setup_root" \
		"$project_setup_edit_target" "$project_setup_edit_link" || return $?
	"$project_setup_replace_port" "$project_setup_root" \
		"$project_setup_target" "$project_setup_link" || return $?
	"$project_setup_replace_port" "$project_setup_root" \
		"$project_setup_edit_target" "$project_setup_edit_link"
)

project_setup_developer_tools() (
	project_setup_root=$1
	project_setup_instructions_target=$2
	project_setup_instructions_link=$3
	project_setup_skills_target=$4
	project_setup_skills_link=$5
	project_setup_vscode_workspace=$6
	project_setup_specs_root=$7
	project_setup_docs_root=$8
	project_setup_work=$9
	shift 9
	project_setup_link_preflight_port=$1
	project_setup_link_replace_port=$2
	project_setup_workspace_preflight_port=$3
	project_setup_workspace_write_port=$4

	# 모든 충돌을 먼저 검사해 일부 파일만 바뀌는 경우를 줄입니다.
	"$project_setup_link_preflight_port" "$project_setup_root" \
		"$project_setup_instructions_target" "$project_setup_instructions_link" || return $?
	"$project_setup_link_preflight_port" "$project_setup_root" \
		"$project_setup_skills_target" "$project_setup_skills_link" || return $?
	"$project_setup_workspace_preflight_port" "$project_setup_root" \
		"$project_setup_vscode_workspace" "$project_setup_specs_root" \
		"$project_setup_docs_root" || return $?

	"$project_setup_link_replace_port" "$project_setup_root" \
		"$project_setup_instructions_target" "$project_setup_instructions_link" || return $?
	"$project_setup_link_replace_port" "$project_setup_root" \
		"$project_setup_skills_target" "$project_setup_skills_link" || return $?
	"$project_setup_workspace_write_port" "$project_setup_root" \
		"$project_setup_vscode_workspace" "$project_setup_specs_root" \
		"$project_setup_docs_root" "$project_setup_work"
)
