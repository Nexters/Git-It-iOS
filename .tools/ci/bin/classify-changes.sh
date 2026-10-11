#!/bin/sh
# PR의 base-head 변경 경로를 NUL-safe하게 분류해 후속 CI job 조건을 출력합니다.

set -eu

classify_changes_main() (
	if [ "$#" -ne 2 ]; then
		printf '오류[ci.classify-changes.invalid-input]: base-sha와 head-sha 두 인자가 필요합니다\n조치: classify-changes.sh <base-sha> <head-sha> 형식으로 실행하세요\n' >&2
		return 2
	fi

	classify_base=$1
	classify_head=$2
	classify_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	classify_suite=$(CDPATH='' cd -- "$classify_bin/.." && pwd -P)
	classify_policy="$classify_suite/core/change-policy.sh"

	# 두 SHA가 commit으로 해석되는지 diff 전에 검증합니다.
	git cat-file -e "${classify_base}^{commit}" 2>/dev/null || {
		printf '오류[ci.classify-changes.base-unreachable]: base SHA %s에 접근할 수 없습니다\n조치: checkout에서 fetch-depth를 늘리거나 base 브랜치를 fetch하세요\n' \
			"$classify_base" >&2
		return 1
	}
	git cat-file -e "${classify_head}^{commit}" 2>/dev/null || {
		printf '오류[ci.classify-changes.head-unreachable]: head SHA %s에 접근할 수 없습니다\n조치: checkout된 head SHA를 확인하세요\n' \
			"$classify_head" >&2
		return 1
	}

	# Git 경로와 정책 token을 호출별 임시 경계에 분리해 저장합니다.
	classify_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-ci-classify.XXXXXX") || return 2
	trap 'rm -rf "$classify_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM
	classify_files="$classify_work/files.nul"
	classify_tokens="$classify_work/tokens"
	if ! git diff --name-only -z "$classify_base" "$classify_head" >"$classify_files"; then
		printf '오류[ci.classify-changes.diff-failed]: diff를 생성할 수 없습니다\n조치: base와 head SHA를 확인하세요\n' >&2
		return 1
	fi
	: >"$classify_tokens"
	if [ -s "$classify_files" ] &&
		! xargs -0 -n 1 /bin/sh "$classify_policy" <"$classify_files" >"$classify_tokens"; then
		printf '오류[ci.classify-changes.policy-failed]: 변경 경로를 분류할 수 없습니다\n조치: change-policy 입력과 진단을 확인하세요\n' >&2
		return 1
	fi

	# 경로 대신 안정 token만 줄 단위로 집계합니다.
	classify_scripts=false
	classify_swift=false
	classify_ui=false
	classify_project_config=false
	classify_workflow=false
	classify_tests=false
	classify_has_non_docs=false
	classify_file_count=0
	while IFS= read -r classify_token; do
		case "$classify_token" in
		file) classify_file_count=$((classify_file_count + 1)) ;;
		docs) : ;;
		non_docs) classify_has_non_docs=true ;;
		scripts) classify_scripts=true ;;
		swift) classify_swift=true ;;
		ui) classify_ui=true ;;
		workflow) classify_workflow=true ;;
		tests) classify_tests=true ;;
		project_config)
			classify_project_config=true
			classify_swift=true
			classify_tests=true
			;;
		source_input | conservative)
			classify_swift=true
			classify_tests=true
			;;
		*)
			printf '오류[ci.classify-changes.unknown-token]: 알 수 없는 분류 token %s\n조치: change-policy와 집계기를 함께 갱신하세요\n' \
				"$classify_token" >&2
			return 2
			;;
		esac
	done <"$classify_tokens"

	if [ "$classify_has_non_docs" = true ]; then
		classify_docs_only=false
	else
		classify_docs_only=true
	fi

	# GitHub output과 로그가 같은 분류 결과를 공유하도록 한 번씩 렌더링합니다.
	if [ -n "${GITHUB_OUTPUT:-}" ]; then
		{
			printf 'docs_only=%s\n' "$classify_docs_only"
			printf 'scripts_changed=%s\n' "$classify_scripts"
			printf 'swift_changed=%s\n' "$classify_swift"
			printf 'ui_changed=%s\n' "$classify_ui"
			printf 'project_config_changed=%s\n' "$classify_project_config"
			printf 'workflow_changed=%s\n' "$classify_workflow"
			printf 'tests_changed=%s\n' "$classify_tests"
		} >>"$GITHUB_OUTPUT"
	fi
	printf 'docs_only=%s\n' "$classify_docs_only"
	printf 'scripts_changed=%s\n' "$classify_scripts"
	printf 'swift_changed=%s\n' "$classify_swift"
	printf 'ui_changed=%s\n' "$classify_ui"
	printf 'project_config_changed=%s\n' "$classify_project_config"
	printf 'workflow_changed=%s\n' "$classify_workflow"
	printf 'tests_changed=%s\n' "$classify_tests"

	if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
		{
			printf '## 변경 분류 결과\n\n'
			printf '| 플래그 | 값 |\n'
			printf '|--------|----|\n'
			printf '| docs_only | %s |\n' "$classify_docs_only"
			printf '| scripts_changed | %s |\n' "$classify_scripts"
			printf '| swift_changed | %s |\n' "$classify_swift"
			printf '| ui_changed | %s |\n' "$classify_ui"
			printf '| project_config_changed | %s |\n' "$classify_project_config"
			printf '| workflow_changed | %s |\n' "$classify_workflow"
			printf '| tests_changed | %s |\n' "$classify_tests"
			printf '\n**변경 파일 수**: %s\n' "$classify_file_count"
		} >>"$GITHUB_STEP_SUMMARY"
	fi
)

classify_changes_main "$@"
