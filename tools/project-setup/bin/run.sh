#!/bin/sh
# shellcheck disable=SC1090,SC1091
set -eu

project_setup_require_relative_path() (
	case "$1" in
	'' | /* | ../* | */../* | */..)
		printf '오류[common.outside-root]: 프로젝트 설정 경로 %s가 저장소 내부 상대경로가 아닙니다\n조치: repository-paths.json의 경로를 확인하세요\n' \
			"$1" >&2
		return 2
		;;
	esac
)

project_setup_main() (
	[ "$#" -eq 1 ] || {
		printf '오류[common.invalid-input]: workspace-link 또는 developer-tools 동작이 필요합니다\n조치: 지원하는 동작 하나를 지정하세요\n' >&2
		return 2
	}
	case "$1" in
	workspace-link | developer-tools) project_setup_operation=$1 ;;
	*)
		printf '오류[common.invalid-input]: 알 수 없는 프로젝트 설정 동작 %s\n조치: workspace-link 또는 developer-tools를 사용하세요\n' \
			"$1" >&2
		return 2
		;;
	esac

	# 공개 진입점의 물리 경로에서 저장소와 모듈을 찾습니다.
	project_setup_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	project_setup_module=$(CDPATH='' cd -- "$project_setup_bin/.." && pwd -P)
	project_setup_root=$(CDPATH='' cd -- "$project_setup_bin/../../.." && pwd -P)
	project_setup_paths="$project_setup_root/tools/repository-paths/bin/repository-paths.sh"
	[ -x "$project_setup_paths" ] || return 2

	. "$project_setup_module/core/link-policy.sh"
	. "$project_setup_module/core/filesystem.sh"
	. "$project_setup_module/core/setup.sh"

	# 모든 링크 경로와 대상을 중앙 JSON 판독기를 통해 읽습니다.
	project_setup_workspace_target=$("$project_setup_paths" GIT_IT_WORKSPACE_PATH) || return $?
	project_setup_workspace_link=$("$project_setup_paths" GIT_IT_WORKSPACE_LINK_PATH) || return $?
	project_setup_edit_workspace_target=$("$project_setup_paths" GIT_IT_EDIT_WORKSPACE_PATH) || return $?
	project_setup_edit_workspace_link=$("$project_setup_paths" GIT_IT_EDIT_WORKSPACE_LINK_PATH) || return $?
	project_setup_instructions_target=$("$project_setup_paths" GIT_IT_AGENT_INSTRUCTIONS_PATH) || return $?
	project_setup_instructions_link=$("$project_setup_paths" GIT_IT_CLAUDE_INSTRUCTIONS_LINK_PATH) || return $?
	project_setup_skills_target=$("$project_setup_paths" GIT_IT_AGENT_SKILLS_ROOT) || return $?
	project_setup_skills_link=$("$project_setup_paths" GIT_IT_CLAUDE_SKILLS_LINK_PATH) || return $?
	project_setup_vscode_workspace=$("$project_setup_paths" GIT_IT_VSCODE_WORKSPACE_PATH) || return $?
	project_setup_specs_root=$("$project_setup_paths" GIT_IT_SPECS_ROOT) || return $?
	project_setup_docs_root=$("$project_setup_paths" GIT_IT_DOCS_ROOT) || return $?
	for project_setup_path in \
		"$project_setup_workspace_target" "$project_setup_workspace_link" \
		"$project_setup_edit_workspace_target" "$project_setup_edit_workspace_link" \
		"$project_setup_instructions_target" "$project_setup_instructions_link" \
		"$project_setup_skills_target" "$project_setup_skills_link" \
		"$project_setup_vscode_workspace" "$project_setup_specs_root" \
		"$project_setup_docs_root"; do
		project_setup_require_relative_path "$project_setup_path" || return $?
	done

	# 생성 중간 파일은 호출별 임시 경계에 격리하고 신호 상태를 보존합니다.
	project_setup_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-project-setup.XXXXXX") || return 2
	trap 'rm -rf "$project_setup_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM

	case "$project_setup_operation" in
	workspace-link)
		project_setup_workspace_links "$project_setup_root" \
			"$project_setup_workspace_target" "$project_setup_workspace_link" \
			"$project_setup_edit_workspace_target" "$project_setup_edit_workspace_link" \
			project_setup_link_preflight project_setup_link_replace
		;;
	developer-tools)
		project_setup_developer_tools "$project_setup_root" \
			"$project_setup_instructions_target" "$project_setup_instructions_link" \
			"$project_setup_skills_target" "$project_setup_skills_link" \
			"$project_setup_vscode_workspace" "$project_setup_specs_root" \
			"$project_setup_docs_root" "$project_setup_work" \
			project_setup_link_preflight project_setup_link_replace \
			project_setup_vscode_workspace_preflight project_setup_vscode_workspace_write
		;;
	esac
)

project_setup_main "$@"
