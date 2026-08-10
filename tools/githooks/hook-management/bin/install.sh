#!/bin/sh
# shellcheck disable=SC1090,SC1091

set -eu

hook_install_main() (
	[ "$#" -eq 0 ] || return 2
	hook_install_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	hook_install_root=$(git -C "$hook_install_bin" rev-parse --show-toplevel 2>/dev/null) || return 2
	hook_install_module=$(CDPATH='' cd -- "$hook_install_bin/.." && pwd -P)
	hook_install_paths="$hook_install_root/tools/repository-paths/bin/repository-paths.sh"
	[ -x "$hook_install_paths" ] || return 2
	# 저장소 밖 훅 패키지의 위치는 중앙 경로 설정으로만 읽습니다.
	hook_install_hooks_root=$("$hook_install_paths" GIT_IT_HOOKS_ROOT) || return $?
	. "$hook_install_module/core/install.sh"
	. "$hook_install_module/core/git-config.sh"
	if hook_install_run hook_git_config_set hook_git_config_prepare hook_git_config_read hook_git_config_verify \
		"$hook_install_root" "$hook_install_hooks_root"; then
		printf 'Git 훅 설정 완료: core.hooksPath=%s\n' "$hook_install_hooks_root"
	else
		printf '오류[hook-management.install-failed]: local hook 설정 또는 권한 준비 실패\n조치: 저장소 local config와 %s 권한을 확인하세요\n' \
			"$hook_install_hooks_root" >&2
		return 1
	fi
)

hook_install_main "$@"
