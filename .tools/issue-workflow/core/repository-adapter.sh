#!/bin/sh
# Git 상태와 편집 대상 경로를 읽는 저장소 어댑터입니다.

repository_adapter_current_branch() (
	git branch --show-current
)

# Git이 무시하는(커밋되지 않는) 경로인지 판정합니다.
repository_adapter_is_ignored() (
	git check-ignore -q -- "$1" 2>/dev/null
)

# hook이 넘긴 JSON에서 편집 대상 경로를 읽습니다.
repository_adapter_tool_file() (
	for repository_adapter_key in tool_input.file_path tool_input.notebook_path; do
		if repository_adapter_value=$(/usr/bin/plutil -extract "$repository_adapter_key" raw -o - "$1" 2>/dev/null); then
			printf '%s\n' "$repository_adapter_value"
			return 0
		fi
	done
	return 1
)

# 저장소 루트 기준 경로를 출력합니다. 저장소 밖이면 실패합니다.
repository_adapter_relative_path() (
	repository_adapter_path=$2
	repository_adapter_tail=''

	# 셸의 pwd -P는 호출 방식에 따라 유니코드 정규화가 달라지므로 루트도 같은 방법으로 풉니다.
	repository_adapter_root=$(readlink -f -- "$1") || return 1

	case "$repository_adapter_path" in
	/*) ;;
	*) repository_adapter_path="$PWD/$repository_adapter_path" ;;
	esac

	# 새 파일은 있는 위쪽 폴더까지 올라가 심볼릭 링크를 풀고 나머지를 다시 붙입니다.
	while [ ! -e "$repository_adapter_path" ] && [ ! -L "$repository_adapter_path" ]; do
		repository_adapter_tail="/${repository_adapter_path##*/}$repository_adapter_tail"
		repository_adapter_path=${repository_adapter_path%/*}
		[ -n "$repository_adapter_path" ] || repository_adapter_path=/
	done
	repository_adapter_physical=$(readlink -f -- "$repository_adapter_path") || return 1
	repository_adapter_full="$repository_adapter_physical$repository_adapter_tail"

	case "$repository_adapter_full" in
	"$repository_adapter_root"/*) printf '%s\n' "${repository_adapter_full#"$repository_adapter_root"/}" ;;
	*) return 1 ;;
	esac
)
