#!/bin/sh
# shellcheck disable=SC1090,SC1091
# 아키텍처 3.1 패키지 의존성 규칙 검사의 공개 진입점입니다.
set -eu

package_dependencies_main() (
	[ "$#" -eq 0 ] || {
		printf '오류[common.invalid-input]: 인자를 받지 않습니다\n조치: 인자 없이 실행하세요\n' >&2
		return 2
	}
	# 공개 진입점의 물리 경로에서 실행 저장소를 해석합니다.
	pd_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	pd_suite=$(CDPATH='' cd -- "$pd_bin/.." && pwd -P)
	pd_root=$(CDPATH='' cd -- "$pd_bin/../../.." && pwd -P)
	pd_paths="$pd_root/tools/repository-paths/bin/repository-paths.sh"
	[ -x "$pd_paths" ] || {
		printf '오류[package-dependencies.missing-paths]: 저장소 경로 판독기를 실행할 수 없습니다\n조치: tools/repository-paths/bin/repository-paths.sh를 복원하세요\n' >&2
		return 2
	}
	pd_projects=$("$pd_paths" --absolute GIT_IT_PROJECTS_ROOT) || return $?
	pd_tuist=$("$pd_paths" --absolute GIT_IT_TUIST_ROOT) || return $?
	pd_architecture=$("$pd_paths" --absolute GIT_IT_ARCHITECTURE_PATH) || return $?
	# 회귀 테스트는 fixture 설정 디렉터리를 주입합니다.
	pd_config=${PACKAGE_DEPENDENCIES_CONFIG_DIR:-$pd_suite/config}

	. "$pd_suite/core/rules-policy.sh"
	. "$pd_suite/core/architecture-table.sh"
	. "$pd_suite/core/manifest.sh"
	. "$pd_suite/core/imports.sh"
	. "$pd_suite/core/judge.sh"
	. "$pd_suite/core/run.sh"

	# 호출별 임시 경계에 수집 레코드를 보관하고 항상 정리합니다.
	pd_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-package-dependencies.XXXXXX") || return 2
	trap 'rm -rf "$pd_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM
	package_dependencies_run \
		"$pd_root" \
		"$pd_projects" \
		"$pd_tuist" \
		"$pd_architecture" \
		"$pd_config" \
		"$pd_work"
)

package_dependencies_main "$@"
