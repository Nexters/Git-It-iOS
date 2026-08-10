#!/bin/sh
# shellcheck disable=SC1090,SC1091
set -eu

script_tests_main() (
	[ "$#" -eq 0 ] || {
		printf '오류[common.invalid-input]: 인자를 받지 않습니다\n조치: 인자 없이 실행하세요\n' >&2
		return 2
	}
	# 공개 진입점의 물리 경로에서 실행 저장소를 해석합니다.
	script_tests_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	script_tests_root=$(CDPATH='' cd -- "$script_tests_bin/../../.." && pwd -P)
	script_tests_suite=$(CDPATH='' cd -- "$script_tests_bin/.." && pwd -P)
	. "$script_tests_suite/core/tests.sh"
	. "$script_tests_suite/core/run.sh"
	# 호출별 임시 경계에 NUL 테스트 목록을 보관하고 항상 정리합니다.
	script_tests_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-script-tests.XXXXXX") || return 2
	trap 'rm -rf "$script_tests_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM
	script_tests_run "$script_tests_root" "$script_tests_work" script_tests_collect script_tests_execute
)

script_tests_main "$@"
