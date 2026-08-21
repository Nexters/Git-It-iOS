#!/bin/sh
# origin/develop부터 HEAD까지의 변경에 CI 조건을 적용하고 실패를 한 번에 보고합니다.

set -eu

ci_pre_push_main() (
	[ "$#" -eq 0 ] || {
		printf '오류[ci.pre-push.invalid-input]: pre-push runner는 인자를 받지 않습니다\n' >&2
		return 2
	}
	ci_pre_push_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	ci_pre_push_root=$(git -C "$ci_pre_push_bin" rev-parse --show-toplevel 2>/dev/null) || return 2
	cd "$ci_pre_push_root" || return 2
	ci_pre_push_paths="$ci_pre_push_root/tools/repository-paths/bin/repository-paths.sh"
	ci_pre_push_classify="$ci_pre_push_bin/classify-changes.sh"
	ci_pre_push_lint="$ci_pre_push_bin/lint-changed-swift.sh"
	[ -x "$ci_pre_push_paths" ] && [ -x "$ci_pre_push_classify" ] && [ -x "$ci_pre_push_lint" ] || return 2
	ci_pre_push_format=$("$ci_pre_push_paths" --absolute GIT_IT_SWIFT_FORMAT_RUNNER) || return $?
	ci_pre_push_build=$("$ci_pre_push_paths" --absolute GIT_IT_PROJECT_BUILD_RUNNER) || return $?
	ci_pre_push_script_tests=$("$ci_pre_push_paths" --absolute GIT_IT_SCRIPT_TEST_RUNNER) || return $?
	ci_pre_push_script_verification=$("$ci_pre_push_paths" --absolute GIT_IT_SCRIPT_VERIFICATION_RUNNER) || return $?
	ci_pre_push_ios_root=$("$ci_pre_push_paths" --absolute GIT_IT_IOS_ROOT) || return $?

	ci_pre_push_base=origin/develop
	ci_pre_push_head=$(git -C "$ci_pre_push_root" rev-parse HEAD) || return 2
	git -C "$ci_pre_push_root" rev-parse --verify --quiet "${ci_pre_push_base}^{commit}" >/dev/null || {
		printf '오류[ci.pre-push.base-unreachable]: %s에 접근할 수 없습니다\n조치: git fetch origin develop 후 다시 push하세요\n' "$ci_pre_push_base" >&2
		return 1
	}
	ci_pre_push_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-ci-pre-push.XXXXXX") || return 2
	trap 'rm -rf "$ci_pre_push_work"' EXIT
	trap 'rm -rf "$ci_pre_push_work"; exit 129' HUP
	trap 'rm -rf "$ci_pre_push_work"; exit 130' INT
	trap 'rm -rf "$ci_pre_push_work"; exit 143' TERM
	ci_pre_push_classification="$ci_pre_push_work/classification"
	ci_pre_push_results="$ci_pre_push_work/results"
	: >"$ci_pre_push_results"

	# CI job 하나를 독립 로그로 실행합니다. 실패해도 뒤 job을 실행해 전체 리포트를 남깁니다.
	ci_pre_push_run() {
		ci_pre_push_name=$1
		shift
		ci_pre_push_log="$ci_pre_push_work/$ci_pre_push_name.log"
		printf '\n== %s ==\n' "$ci_pre_push_name"
		if "$@" >"$ci_pre_push_log" 2>&1; then
			cat "$ci_pre_push_log"
			printf '%s|success|%s\n' "$ci_pre_push_name" "$ci_pre_push_log" >>"$ci_pre_push_results"
		else
			ci_pre_push_status=$?
			cat "$ci_pre_push_log" >&2
			printf '%s|failure:%s|%s\n' "$ci_pre_push_name" "$ci_pre_push_status" "$ci_pre_push_log" >>"$ci_pre_push_results"
		fi
	}

	ci_pre_push_run changes "$ci_pre_push_classify" "$ci_pre_push_base" "$ci_pre_push_head"
	cp "$ci_pre_push_work/changes.log" "$ci_pre_push_classification"
	if grep -q '^changes|failure:' "$ci_pre_push_results"; then
		# 분류 실패 시 조건부 job을 안전하게 선택할 수 없으므로 리포트만 작성합니다.
		ci_pre_push_report "$ci_pre_push_results"
		return 1
	fi
	ci_pre_push_scripts=$(sed -n 's/^scripts_changed=//p' "$ci_pre_push_classification")
	ci_pre_push_swift=$(sed -n 's/^swift_changed=//p' "$ci_pre_push_classification")
	ci_pre_push_ui=$(sed -n 's/^ui_changed=//p' "$ci_pre_push_classification")
	ci_pre_push_project=$(sed -n 's/^project_config_changed=//p' "$ci_pre_push_classification")
	ci_pre_push_tests=$(sed -n 's/^tests_changed=//p' "$ci_pre_push_classification")

	if [ "$ci_pre_push_scripts" = true ]; then
		ci_pre_push_run script-tests "$ci_pre_push_script_tests"
		ci_pre_push_run script-quality "$ci_pre_push_script_verification"
	fi
	if [ "$ci_pre_push_swift" = true ]; then
		# lint 전에 변경 Swift 파일을 교정합니다. 포맷 결과는 push에 포함되지 않으므로 후속 commit이 필요합니다.
		ci_pre_push_run swift-format ci_pre_push_format_changed \
			"$ci_pre_push_root" "$ci_pre_push_base" "$ci_pre_push_head" \
			"$ci_pre_push_work" "$ci_pre_push_format"
		ci_pre_push_run swift-lint "$ci_pre_push_lint" "$ci_pre_push_base" "$ci_pre_push_head"
	fi
	if [ "$ci_pre_push_swift" = true ] || [ "$ci_pre_push_project" = true ]; then
		ci_pre_push_run workspace ci_pre_push_prepare_workspace "$ci_pre_push_ios_root"
		if [ "$ci_pre_push_project" = true ]; then ci_pre_push_run app-build "$ci_pre_push_build" build; else ci_pre_push_run app-build "$ci_pre_push_build" build-app; fi
	fi
	# pre-push에서만 보존되는 테스트 결과를 DerivedData 아래에 남깁니다.
	export GIT_IT_XCRESULTS_PATH="$ci_pre_push_ios_root/DerivedData/PrePushTestResults"
	if [ "$ci_pre_push_swift" = true ] || [ "$ci_pre_push_tests" = true ] || [ "$ci_pre_push_project" = true ]; then
		ci_pre_push_run unit-compile "$ci_pre_push_build" compile-unit
		ci_pre_push_run unit-tests "$ci_pre_push_build" test-unit
	fi
	if [ "$ci_pre_push_ui" = true ]; then
		ci_pre_push_run ui-compile "$ci_pre_push_build" compile-ui
		ci_pre_push_run ui-tests "$ci_pre_push_build" test-ui
	fi
	ci_pre_push_report "$ci_pre_push_results"
)

ci_pre_push_format_changed() (
	ci_pre_push_format_root=$1
	ci_pre_push_format_base=$2
	ci_pre_push_format_head=$3
	ci_pre_push_format_work=$4
	ci_pre_push_format_runner=$5
	ci_pre_push_changed_swift="$ci_pre_push_format_work/changed-swift.nul"
	ci_pre_push_backup="$ci_pre_push_format_work/original"
	ci_pre_push_corrected="$ci_pre_push_format_work/corrected.nul"
	git -C "$ci_pre_push_format_root" diff --name-only -z --diff-filter=ACMR \
		"$ci_pre_push_format_base" "$ci_pre_push_format_head" -- '*.swift' >"$ci_pre_push_changed_swift" || return 1
	[ -s "$ci_pre_push_changed_swift" ] || return 0
	# 기존 미커밋 변경과 구분하기 위해 포맷 대상의 invocation 전 바이트를 보관합니다.
	mkdir -p "$ci_pre_push_backup" || return 2
	# shellcheck disable=SC2016
	xargs -0 -n 1 /bin/sh -c '
		backup=$1
		path=$2
		mkdir -p "$(dirname -- "$backup/$path")" || exit 1
		cp -p -- "$path" "$backup/$path"
	' sh "$ci_pre_push_backup" <"$ci_pre_push_changed_swift" || return 2
	(
		cd "$ci_pre_push_format_root"
		xargs -0 "$ci_pre_push_format_runner" format <"$ci_pre_push_changed_swift"
	)
	: >"$ci_pre_push_corrected"
	# shellcheck disable=SC2016
	xargs -0 -n 1 /bin/sh -c '
		backup=$1
		changed=$2
		path=$3
		if ! cmp -s "$path" "$backup/$path"; then printf "%s\\0" "$path" >>"$changed"; fi
	' sh "$ci_pre_push_backup" "$ci_pre_push_corrected" <"$ci_pre_push_changed_swift" || return 2
	if [ -s "$ci_pre_push_corrected" ]; then
		printf '교정[ci.pre-push.format-corrected]: Swift 포맷 변경을 만들었습니다. 검토·stage·commit 후 다시 push하세요\n' >&2
		return 3
	fi
)

ci_pre_push_prepare_workspace() (
	ci_pre_push_workspace_ios=$1
	# CI의 build/test job과 같은 Tuist 의존성 해결과 workspace 생성을 한 번 수행합니다.
	(
		cd "$ci_pre_push_workspace_ios"
		tuist install
		tuist generate --no-open
	)
)

ci_pre_push_report() {
	ci_pre_push_report_results=$1
	ci_pre_push_report_failed=false
	printf '\npre-push CI 리포트\n'
	printf '| 단계 | 결과 |\n| --- | --- |\n'
	while IFS='|' read -r ci_pre_push_report_name ci_pre_push_report_result ci_pre_push_report_log; do
		printf '| %s | %s |\n' "$ci_pre_push_report_name" "$ci_pre_push_report_result"
		case "$ci_pre_push_report_result" in failure:*) ci_pre_push_report_failed=true ;; esac
	done <"$ci_pre_push_report_results"
	if [ "$ci_pre_push_report_failed" = true ]; then
		printf '\n실패 상세:\n' >&2
		while IFS='|' read -r ci_pre_push_report_name ci_pre_push_report_result ci_pre_push_report_log; do
			case "$ci_pre_push_report_result" in
			failure:*)
				printf '\n--- %s (%s) ---\n' "$ci_pre_push_report_name" "$ci_pre_push_report_result" >&2
				sed -n '1,160p' "$ci_pre_push_report_log" >&2
				;;
			esac
		done <"$ci_pre_push_report_results"
		printf '\n오류[ci.pre-push.failed]: 실패 단계를 고친 뒤 다시 push하세요\n' >&2
		return 1
	fi
	printf '결과: 성공\n'
}

ci_pre_push_main "$@"
