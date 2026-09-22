#!/bin/sh
# 초기화 파일의 상태를 검사하고 심볼릭 링크와 VS Code workspace를 기록합니다.

project_setup_link_state() (
	project_setup_link_path=$1
	if [ -L "$project_setup_link_path" ]; then
		printf 'symlink\n'
	elif [ -d "$project_setup_link_path" ]; then
		printf 'directory\n'
	elif [ -e "$project_setup_link_path" ]; then
		printf 'file\n'
	else
		printf 'absent\n'
	fi
)

# 대상 누락과 일반 파일 충돌을 실제 변경 전에 차단합니다.
project_setup_link_preflight() (
	project_setup_root=$1
	project_setup_target_relative=$2
	project_setup_link_relative=$3
	project_setup_target="$project_setup_root/$project_setup_target_relative"
	project_setup_link="$project_setup_root/$project_setup_link_relative"

	[ -e "$project_setup_target" ] || {
		printf '오류[project-setup.missing-target]: 링크 대상 %s 누락\n조치: 대상 파일 또는 디렉터리를 먼저 생성하세요\n' \
			"$project_setup_target" >&2
		return 2
	}
	project_setup_state=$(project_setup_link_state "$project_setup_link") || return $?
	project_setup_decision=$(project_setup_link_policy_decide "$project_setup_state") || return $?
	[ "$project_setup_decision" != conflict ] || {
		printf '오류[project-setup.path-conflict]: 심볼릭 링크 위치 %s에 일반 %s가 존재합니다\n조치: 해당 항목을 직접 이동하거나 삭제한 뒤 다시 실행하세요\n' \
			"$project_setup_link" "$project_setup_state" >&2
		return 2
	}
)

# 기존 링크의 대상을 보관해 새 링크 생성 실패 시 원래 링크를 복구합니다.
project_setup_link_replace() (
	project_setup_root=$1
	project_setup_target_relative=$2
	project_setup_link_relative=$3
	project_setup_link="$project_setup_root/$project_setup_link_relative"
	project_setup_previous_target=

	if [ -L "$project_setup_link" ]; then
		project_setup_previous_target=$(readlink "$project_setup_link") || return 2
		rm -f -- "$project_setup_link" || return 2
	fi
	if ln -s "$project_setup_target_relative" "$project_setup_link"; then
		printf '심볼릭 링크 생성: %s -> %s\n' \
			"$project_setup_link_relative" "$project_setup_target_relative"
		return 0
	fi
	if [ -n "$project_setup_previous_target" ]; then
		ln -s "$project_setup_previous_target" "$project_setup_link" || {
			printf '오류[project-setup.write-failed]: %s 링크 생성과 원래 링크 복구에 실패했습니다\n조치: 링크 경로의 권한과 파일 시스템 상태를 확인하세요\n' \
				"$project_setup_link" >&2
			return 2
		}
	fi
	printf '오류[project-setup.write-failed]: %s 심볼릭 링크 생성 실패\n조치: 링크 경로의 권한과 파일 시스템 상태를 확인하세요\n' \
		"$project_setup_link" >&2
	return 2
)

# 기존 일반 workspace 파일은 원자적으로 갱신하되 링크와 디렉터리는 덮어쓰지 않습니다.
project_setup_vscode_workspace_preflight() (
	project_setup_root=$1
	project_setup_workspace_relative=$2
	project_setup_specs_relative=$3
	project_setup_docs_relative=$4
	project_setup_workspace="$project_setup_root/$project_setup_workspace_relative"

	for project_setup_folder_relative in \
		"$project_setup_specs_relative" "$project_setup_docs_relative"; do
		[ -d "$project_setup_root/$project_setup_folder_relative" ] || {
			printf '오류[project-setup.missing-target]: VS Code 폴더 %s 누락\n조치: 대상 디렉터리를 먼저 생성하세요\n' \
				"$project_setup_root/$project_setup_folder_relative" >&2
			return 2
		}
	done
	if [ -L "$project_setup_workspace" ] || [ -d "$project_setup_workspace" ]; then
		printf '오류[project-setup.path-conflict]: VS Code workspace 위치 %s에 덮어쓸 수 없는 항목이 존재합니다\n조치: 해당 항목을 직접 이동하거나 삭제한 뒤 다시 실행하세요\n' \
			"$project_setup_workspace" >&2
		return 2
	fi
)

project_setup_json_escape() {
	# 경로 문자열을 JSON 문자열 값으로 안전하게 변환합니다.
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

project_setup_vscode_workspace_write() (
	project_setup_root=$1
	project_setup_workspace_relative=$2
	project_setup_specs_relative=$3
	project_setup_docs_relative=$4
	project_setup_work=$5
	project_setup_workspace="$project_setup_root/$project_setup_workspace_relative"
	project_setup_temporary="$project_setup_work/vscode-workspace.json"
	project_setup_specs_json=$(project_setup_json_escape "$project_setup_specs_relative") || return 2
	project_setup_docs_json=$(project_setup_json_escape "$project_setup_docs_relative") || return 2

	# 완성된 JSON만 목적지로 이동해 기존 파일의 부분 기록을 방지합니다.
	printf '{\n  "folders": [\n    { "path": "%s" },\n    { "path": "%s" }\n  ],\n  "settings": {}\n}\n' \
		"$project_setup_specs_json" "$project_setup_docs_json" >"$project_setup_temporary" || return 2
	if ! /usr/bin/plutil -extract folders.0.path raw \
		"$project_setup_temporary" >/dev/null 2>&1 ||
		! /usr/bin/plutil -extract folders.1.path raw \
			"$project_setup_temporary" >/dev/null 2>&1; then
		printf '오류[project-setup.write-failed]: VS Code workspace JSON 생성 실패\n조치: JSON에 사용할 저장소 경로 설정을 확인하세요\n' >&2
		return 2
	fi
	mv -f -- "$project_setup_temporary" "$project_setup_workspace" || {
		printf '오류[project-setup.write-failed]: %s 기록 실패\n조치: 파일 경로의 권한과 파일 시스템 상태를 확인하세요\n' \
			"$project_setup_workspace" >&2
		return 2
	}
	printf 'VS Code workspace 생성: %s\n' "$project_setup_workspace_relative"
)

# 기존 로컬 설정을 보존하기 위해 생성 전에 파일 상태를 검증합니다.
project_setup_xcconfig_preflight() (
	project_setup_xcconfig_path=$1
	if [ -L "$project_setup_xcconfig_path" ] || [ -e "$project_setup_xcconfig_path" ]; then
		[ -f "$project_setup_xcconfig_path" ] || {
			printf '오류[project-setup.path-conflict]: xcconfig 위치 %s에 일반 파일이 아닌 항목이 존재합니다\n조치: 해당 항목을 이동하거나 올바른 xcconfig 파일로 교체하세요\n' \
				"$project_setup_xcconfig_path" >&2
			return 2
		}
	fi
)

# 누락된 로컬 설정 파일만 만들고 기존 파일이나 디렉터리는 덮어쓰지 않습니다.
project_setup_xcconfig_ensure() (
	project_setup_xcconfig_path=$1
	[ -e "$project_setup_xcconfig_path" ] && return 0

	# 부모 디렉터리를 먼저 만든 뒤 제한된 권한의 빈 템플릿을 생성합니다.
	mkdir -p -- "$(dirname -- "$project_setup_xcconfig_path")" || return 2
	(umask 077 && : >"$project_setup_xcconfig_path") || {
		printf '오류[project-setup.write-failed]: xcconfig 파일 %s 생성 실패\n조치: 경로 권한과 파일 시스템 상태를 확인하세요\n' \
			"$project_setup_xcconfig_path" >&2
		return 2
	}
	printf 'xcconfig 생성: %s\n' "$project_setup_xcconfig_path"
)
