#!/bin/sh
# tools/repository-paths의 JSON을 검증해 읽는 공용 진입점입니다.

set -eu

# 공개된 경로 환경변수의 순서와 허용 목록을 한 곳에서 유지합니다.
repository_paths_keys() {
	printf '%s\n' \
		GIT_IT_PATHS_FILE \
		GIT_IT_IOS_ROOT \
		GIT_IT_PROJECTS_ROOT \
		GIT_IT_TUIST_ROOT \
		GIT_IT_WORKSPACE_PATH \
		GIT_IT_WORKSPACE_LINK_PATH \
		GIT_IT_DERIVED_DATA_PATH \
		GIT_IT_SWIFT_STYLE_ROOT \
		GIT_IT_HOOKS_ROOT \
		GIT_IT_ARCHITECTURE_PATH \
		GIT_IT_AGENT_INSTRUCTIONS_PATH \
		GIT_IT_AGENT_SKILLS_ROOT \
		GIT_IT_CLAUDE_INSTRUCTIONS_LINK_PATH \
		GIT_IT_CLAUDE_SKILLS_LINK_PATH \
		GIT_IT_VSCODE_WORKSPACE_PATH \
		GIT_IT_SPECS_ROOT \
		GIT_IT_DOCS_ROOT \
		GIT_IT_SWIFT_FORMAT_RUNNER \
		GIT_IT_PROJECT_BUILD_RUNNER \
		GIT_IT_PROJECT_SETUP_RUNNER \
		GIT_IT_SCRIPT_TEST_RUNNER \
		GIT_IT_SCRIPT_VERIFICATION_RUNNER
}

# JSON 문자열 하나를 읽고 저장소 밖을 가리키지 않는 상대경로인지 확인합니다.
repository_paths_read() (
	repository_paths_config=$1
	repository_paths_key=$2

	repository_paths_allowed=false
	repository_paths_key_list=$(repository_paths_keys)
	while IFS= read -r repository_paths_known_key; do
		if [ "$repository_paths_key" = "$repository_paths_known_key" ]; then
			repository_paths_allowed=true
			break
		fi
	done <<EOF
$repository_paths_key_list
EOF
	if [ "$repository_paths_allowed" != true ]; then
		printf '오류[repository-paths.unknown-key]: 알 수 없는 경로 키 %s\n조치: repository-paths.json의 공개 키를 사용하세요\n' \
			"$repository_paths_key" >&2
		return 2
	fi

	[ -f "$repository_paths_config" ] || {
		printf '오류[repository-paths.missing-config]: %s 누락\n조치: tools/repository-paths의 경로 설정 파일을 복원하세요\n' \
			"$repository_paths_config" >&2
		return 2
	}
	[ -x /usr/bin/plutil ] || {
		printf '오류[common.missing-tool]: /usr/bin/plutil을 찾을 수 없습니다\n조치: macOS Command Line Tools를 활성화하세요\n' >&2
		return 2
	}

	repository_paths_value=$(/usr/bin/plutil -extract "$repository_paths_key" raw \
		-expect string -- "$repository_paths_config" 2>/dev/null) || {
		printf '오류[repository-paths.invalid-config]: %s에서 문자열 키 %s를 읽을 수 없습니다\n조치: JSON 구문과 필수 경로 키를 확인하세요\n' \
			"$repository_paths_config" "$repository_paths_key" >&2
		return 2
	}
	[ -n "$repository_paths_value" ] || {
		printf '오류[repository-paths.invalid-path]: %s 값이 비어 있습니다\n조치: 저장소 상대경로를 지정하세요\n' \
			"$repository_paths_key" >&2
		return 2
	}
	case "$repository_paths_value" in
	/* | ../* | */../* | */.. | *'='* | *'
'*)
		printf '오류[repository-paths.invalid-path]: %s=%s 는 안전한 저장소 상대경로가 아닙니다\n조치: 절대경로, 상위 경로, 개행과 등호를 제거하세요\n' \
			"$repository_paths_key" "$repository_paths_value" >&2
		return 2
		;;
	esac
	printf '%s\n' "$repository_paths_value"
)

# 명시적으로 전달된 환경변수를 JSON 기본값보다 우선합니다.
repository_paths_get() (
	repository_paths_config=$1
	repository_paths_key=$2
	if repository_paths_environment=$(/usr/bin/printenv "$repository_paths_key" 2>/dev/null) &&
		[ -n "$repository_paths_environment" ]; then
		case "$repository_paths_environment" in
		../* | */../* | */.. | *'='* | *'
'*)
			printf '오류[repository-paths.invalid-path]: %s 환경변수가 안전한 경로가 아닙니다\n조치: 상위 경로, 개행과 등호를 제거하세요\n' \
				"$repository_paths_key" >&2
			return 2
			;;
		esac
		printf '%s\n' "$repository_paths_environment"
		return
	fi
	repository_paths_read "$repository_paths_config" "$repository_paths_key"
)

# 저장소 상대경로는 저장소 루트에 결합하고 절대경로 override는 그대로 유지합니다.
repository_paths_absolute() (
	repository_paths_root=$1
	repository_paths_value=$2
	case "$repository_paths_value" in
	/*) printf '%s\n' "$repository_paths_value" ;;
	*) printf '%s/%s\n' "$repository_paths_root" "$repository_paths_value" ;;
	esac
)

repository_paths_main() (
	repository_paths_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	repository_paths_root=$(CDPATH='' cd -- "$repository_paths_bin/../../.." && pwd -P)
	repository_paths_config_value=${GIT_IT_PATHS_FILE:-tools/repository-paths/repository-paths.json}
	case "$repository_paths_config_value" in
	/*) repository_paths_config=$repository_paths_config_value ;;
	*) repository_paths_config="$repository_paths_root/$repository_paths_config_value" ;;
	esac

	# 인자가 없으면 CI가 바로 적재할 수 있는 KEY=value 목록을 출력합니다.
	if [ "$#" -eq 0 ]; then
		repository_paths_key_list=$(repository_paths_keys)
		while IFS= read -r repository_paths_key; do
			repository_paths_value=$(repository_paths_get "$repository_paths_config" \
				"$repository_paths_key") || return $?
			printf '%s=%s\n' "$repository_paths_key" "$repository_paths_value"
		done <<EOF
$repository_paths_key_list
EOF
		return
	fi

	if [ "$#" -eq 2 ] && [ "$1" = --absolute ]; then
		repository_paths_value=$(repository_paths_get "$repository_paths_config" "$2") || return $?
		repository_paths_absolute "$repository_paths_root" "$repository_paths_value"
		return
	fi

	[ "$#" -eq 1 ] || {
		printf '오류[common.invalid-input]: 경로 키 또는 --absolute KEY가 필요합니다\n조치: 인자 없이 전체 환경을 출력하거나 공개 키 하나를 지정하세요\n' >&2
		return 2
	}
	repository_paths_get "$repository_paths_config" "$1"
)

repository_paths_main "$@"
