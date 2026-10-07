#!/bin/sh
# shellcheck disable=SC1090,SC1091
# 디자인 규격 금지 패턴 검사의 공개 진입점입니다.
set -eu

design_rules_main() (
	[ "$#" -eq 0 ] || {
		printf '오류[common.invalid-input]: 인자를 받지 않습니다\n조치: 인자 없이 실행하세요\n' >&2
		return 2
	}
	# 공개 진입점의 물리 경로에서 실행 저장소를 해석합니다.
	design_rules_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	design_rules_suite=$(CDPATH='' cd -- "$design_rules_bin/.." && pwd -P)
	design_rules_root=$(CDPATH='' cd -- "$design_rules_bin/../../.." && pwd -P)
	design_rules_paths="$design_rules_root/tools/repository-paths/bin/repository-paths.sh"
	[ -x "$design_rules_paths" ] || {
		printf '오류[design-rules.missing-paths]: 저장소 경로 판독기를 실행할 수 없습니다\n조치: tools/repository-paths/bin/repository-paths.sh를 복원하세요\n' >&2
		return 2
	}
	command -v rg >/dev/null 2>&1 || {
		printf '오류[design-rules.missing-ripgrep]: rg를 찾을 수 없습니다\n조치: ripgrep을 설치한 뒤 다시 실행하세요\n' >&2
		return 2
	}
	design_rules_projects=$("$design_rules_paths" --absolute GIT_IT_PROJECTS_ROOT) || return $?

	. "$design_rules_suite/core/rules.sh"
	. "$design_rules_suite/core/scan.sh"
	. "$design_rules_suite/core/run.sh"

	# 호출별 임시 경계에 위반 목록을 보관하고 항상 정리합니다.
	design_rules_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-design-rules.XXXXXX") || return 2
	trap 'rm -rf "$design_rules_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM
	design_rules_run \
		"$design_rules_projects" \
		"$design_rules_suite/config" \
		"$design_rules_suite/core" \
		"$design_rules_work"
)

design_rules_main "$@"
