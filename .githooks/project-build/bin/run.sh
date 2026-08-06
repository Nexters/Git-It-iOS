#!/bin/sh
# shellcheck disable=SC1090,SC2329

set -eu

project_build_main() (
	if [ "$#" -ne 1 ]; then
		printf '오류[common.invalid-input]: ACTION 한 개가 필요합니다\n조치: build, compile, test 공개 명령을 사용하세요\n' >&2
		return 2
	fi

	project_build_operation=$1
	project_build_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	project_build_root=$(git -C "$project_build_bin" rev-parse --show-toplevel 2>/dev/null) || {
		printf '오류[common.invalid-input]: Git 저장소를 찾을 수 없습니다\n조치: 저장소 안에서 실행하세요\n' >&2
		return 2
	}
	project_build_workspace="$project_build_root/GitIt.xcworkspace"
	project_build_derived=${GIT_IT_DERIVED_DATA_PATH:-"$project_build_root/DerivedData/PreCommit"}
	project_build_xcode_adapter="$project_build_root/.githooks/project-build/core/xcodebuild.sh"
	project_build_workspace_adapter="$project_build_root/.githooks/project-build/core/workspace.sh"

	. "$project_build_root/.githooks/project-build/core/run-all.sh"
	. "$project_build_root/.githooks/project-build/core/scheme-policy.sh"
	. "$project_build_workspace_adapter"
	. "$project_build_xcode_adapter"

	project_build_action=$(scheme_policy_xcode_action "$project_build_operation") || {
		printf '오류[common.invalid-input]: 지원하지 않는 ACTION=%s\n조치: build, compile, test 중 하나를 사용하세요\n' "$project_build_operation" >&2
		return 2
	}
	case "$project_build_operation" in
	build)
		project_build_scope=all
		project_build_destination='generic/platform=iOS Simulator'
		;;
	compile | test)
		project_build_scope=testable
		project_build_destination=${GIT_IT_TEST_DESTINATION:-'platform=iOS Simulator,name=iPhone 17 Pro'}
		[ -n "$project_build_destination" ] || {
			printf '오류[common.invalid-input]: GIT_IT_TEST_DESTINATION이 비어 있습니다\n조치: 유효한 iOS Simulator destination을 지정하세요\n' >&2
			return 2
		}
		;;
	esac

	[ -d "$project_build_workspace" ] || {
		printf '오류[project-build.missing-workspace]: %s 누락\n조치: tuist generate를 실행하세요\n' "$project_build_workspace" >&2
		return 2
	}
	command -v xcodebuild >/dev/null 2>&1 || {
		printf '오류[common.missing-tool]: xcodebuild를 찾을 수 없습니다\n조치: Xcode Command Line Tools를 활성화하세요\n' >&2
		return 2
	}

	project_build_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-project-build.XXXXXX") || return 2
	trap 'rm -rf "$project_build_work"' EXIT
	trap 'rm -rf "$project_build_work"; exit 129' HUP
	trap 'rm -rf "$project_build_work"; exit 130' INT
	trap 'rm -rf "$project_build_work"; exit 143' TERM
	project_build_observed="$project_build_work/observed.nul"
	project_build_targets="$project_build_work/targets.nul"
	project_build_results="$project_build_work/results"

	project_build_observe() {
		project_workspace_observe "$project_build_root" "$project_build_scope" \
			"$1" "$2" "$project_build_workspace_adapter"
	}
	project_build_execute() {
		project_xcodebuild_all "$project_build_workspace" "$project_build_derived" \
			"$project_build_destination" "$project_build_operation" "$project_build_action" \
			"$1" "$2" "$project_build_xcode_adapter"
	}

	if project_run_all project_build_observe project_build_execute \
		"$project_build_observed" "$project_build_targets" "$project_build_results"; then
		project_build_exit=0
	else
		project_build_exit=$?
	fi

	if [ ! -s "$project_build_targets" ]; then
		if [ "$project_build_scope" = testable ] && [ -s "$project_build_observed" ]; then
			printf '건너뜀[project-build.no-test-schemes]: 테스트가 연결된 공유 scheme이 없습니다\n'
			return 0
		fi
		printf '오류[project-build.no-schemes]: 공유 scheme이 없습니다\n조치: Tuist 프로젝트를 생성하고 shared scheme 설정을 확인하세요\n' >&2
		return 2
	fi

	project_build_attempted=$(wc -l <"$project_build_results" | tr -d ' ')
	project_build_failed=$(grep -c '^failed' "$project_build_results" 2>/dev/null || true)
	project_build_succeeded=$(grep -c '^succeeded' "$project_build_results" 2>/dev/null || true)
	printf '프로젝트 요약: 작업=%s 시도=%s 성공=%s 실패=%s\n' \
		"$project_build_operation" "$project_build_attempted" \
		"$project_build_succeeded" "$project_build_failed"
	[ "$project_build_exit" -eq 0 ] || {
		printf '조치: 위 실패 scheme의 로그, simulator와 패키지 의존성을 확인하세요\n' >&2
		return 1
	}
)

project_build_main "$@"
