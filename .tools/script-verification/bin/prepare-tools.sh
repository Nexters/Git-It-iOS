#!/bin/sh
# shellcheck disable=SC1090,SC1091

set -eu

verification_prepare_main() (
	[ "$#" -eq 0 ] || return 2
	verification_prepare_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	verification_prepare_suite=$(CDPATH='' cd -- "$verification_prepare_bin/.." && pwd -P)
	verification_prepare_adapter="$verification_prepare_suite/core/tool-dependency.sh"
	. "$verification_prepare_suite/core/prepare-tools.sh"
	. "$verification_prepare_adapter"
	VERIFICATION_SUITE_ROOT=$verification_prepare_suite
	VERIFICATION_PLATFORM=$(verification_platform_detect) || {
		printf '오류[script-verification.dependency-prepare-failed]: 지원하지 않는 platform\n조치: tools.lock의 지원 platform을 확인하세요\n' >&2
		return 2
	}
	VERIFICATION_WORK=$(mktemp -d "${TMPDIR:-/tmp}/git-it-prepare-tools.XXXXXX") || return 2
	export VERIFICATION_SUITE_ROOT VERIFICATION_PLATFORM VERIFICATION_WORK
	trap 'rm -rf "$VERIFICATION_WORK"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM
	if prepare_tools_run verification_lock_read verification_artifacts_fetch \
		verification_artifacts_check verification_artifacts_place; then
		printf '검증 도구 준비 완료: ShellCheck 0.11.0, shfmt 3.13.1\n'
	else
		verification_prepare_exit=$?
		printf '오류[script-verification.dependency-prepare-failed]: artifact 준비 실패\n조치: 네트워크와 tools.lock checksum을 확인한 뒤 다시 실행하세요\n' >&2
		return "$verification_prepare_exit"
	fi
)

verification_prepare_main "$@"
