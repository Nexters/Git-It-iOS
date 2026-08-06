#!/bin/sh

set -eu

hook_install_main() (
	[ "$#" -eq 0 ] || return 2
	hook_install_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	HOOK_REPOSITORY_ROOT=$(git -C "$hook_install_bin" rev-parse --show-toplevel 2>/dev/null) || return 2
	export HOOK_REPOSITORY_ROOT
	. "$HOOK_REPOSITORY_ROOT/.githooks/hook-management/core/install.sh"
	. "$HOOK_REPOSITORY_ROOT/.githooks/hook-management/core/git-config.sh"
	if hook_install_run hook_git_config_set hook_git_config_prepare hook_git_config_read hook_git_config_verify; then
		printf 'Git 훅 설정 완료: core.hooksPath=.githooks\n'
	else
		printf '오류[hook-management.install-failed]: local hook 설정 또는 권한 준비 실패\n조치: 저장소 local config와 .githooks 권한을 확인하세요\n' >&2
		return 1
	fi
)

hook_install_main "$@"
