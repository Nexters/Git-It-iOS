#!/bin/sh
# shellcheck disable=SC1090,SC1091

set -eu

verification_main() (
	[ "$#" -eq 0 ] || {
		printf '오류[common.invalid-input]: 인자를 받지 않습니다\n' >&2
		return 2
	}
	verification_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	verification_suite=$(CDPATH='' cd -- "$verification_bin/.." && pwd -P)
	verification_root=$(git -C "$verification_suite" rev-parse --show-toplevel 2>/dev/null) || return 2
	verification_paths="$verification_root/tools/repository-paths/bin/repository-paths.sh"
	[ -x "$verification_paths" ] || return 2
	verification_skill="$verification_root/.agents/skills/write-project-scripts"
	[ -f "$verification_skill/SKILL.md" ] || return 2
	verification_references="$verification_skill/references"
	verification_adapter="$verification_suite/core/regression.sh"
	. "$verification_suite/core/verify.sh"
	. "$verification_suite/core/tool-dependency.sh"
	. "$verification_suite/core/shellcheck.sh"
	. "$verification_suite/core/shfmt.sh"
	. "$verification_adapter"
	VERIFICATION_ROOT=$verification_root
	VERIFICATION_SUITE_ROOT=$verification_suite
	VERIFICATION_REFERENCE_ROOT=$verification_references
	# 정적 검사 대상의 외부 훅 루트는 중앙 설정에서 한 번만 읽습니다.
	VERIFICATION_GITHOOKS_ROOT=$("$verification_paths" GIT_IT_HOOKS_ROOT) || return $?
	VERIFICATION_PLATFORM=$(verification_platform_detect) || return 2
	export VERIFICATION_ROOT VERIFICATION_SUITE_ROOT VERIFICATION_REFERENCE_ROOT VERIFICATION_GITHOOKS_ROOT VERIFICATION_PLATFORM
	if verify_run verification_dependency_check verification_static_run \
		verification_regression_run verification_checklist_run; then
		printf '스크립트 검증 완료\n'
	else
		printf '오류[script-verification.regression-failed]: 하나 이상의 검증 단계 실패\n조치: 위 단계별 진단을 해결한 뒤 다시 실행하세요\n' >&2
		return 1
	fi
)

verification_main "$@"
