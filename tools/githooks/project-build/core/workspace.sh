#!/bin/sh
# 생성 workspace의 공유 scheme과 테스트 연결 여부를 관찰합니다.

project_workspace_observe() (
	project_workspace_projects=$1
	project_workspace_workspace=$2
	project_workspace_scope=$3
	project_workspace_scheme_filter=$4
	project_workspace_observed=$5
	project_workspace_targets=$6
	project_workspace_helper=$7

	[ -d "$project_workspace_projects" ] || return 2
	: >"$project_workspace_observed"
	: >"$project_workspace_targets"
	find "$project_workspace_projects" "$project_workspace_workspace" \
		-path '*/xcshareddata/xcschemes/*.xcscheme' \
		-type f \
		-print0 2>/dev/null >"$project_workspace_observed" || return 2
	[ -s "$project_workspace_observed" ] || return 0

	xargs -0 -n 1 "$project_workspace_helper" --select-one \
		"$project_workspace_projects" "$project_workspace_workspace" \
		"$project_workspace_scope" "$project_workspace_scheme_filter" \
		"$project_workspace_targets" <"$project_workspace_observed"
)

project_workspace_select_one() {
	project_workspace_projects=$1
	project_workspace_workspace=$2
	project_workspace_scope=$3
	project_workspace_scheme_filter=$4
	project_workspace_targets=$5
	project_workspace_scheme_file=$6
	project_workspace_adapter=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	. "$project_workspace_adapter/../core/scheme-policy.sh"
	project_workspace_scheme_name=$(basename -- "$project_workspace_scheme_file" .xcscheme)

	# 호출자가 지정한 scheme만 후속 Xcode action 대상으로 전달합니다.
	project_workspace_name_decision=$(scheme_policy_match_name \
		"$project_workspace_scheme_filter" "$project_workspace_scheme_name") || return 2
	[ "$project_workspace_name_decision" = eligible ] || return 0

	if grep -q '<TestableReference' "$project_workspace_scheme_file"; then
		project_workspace_has_tests=true
	else
		project_workspace_grep_exit=$?
		[ "$project_workspace_grep_exit" -eq 1 ] || return 2
		project_workspace_has_tests=false
	fi

	project_workspace_decision=$(scheme_policy_decide \
		"$project_workspace_projects" "$project_workspace_workspace" \
		"$project_workspace_scheme_file" \
		"$project_workspace_scope" "$project_workspace_has_tests") || return 2
	[ "$project_workspace_decision" = eligible ] || return 0
	printf '%s\0' "$project_workspace_scheme_file" >>"$project_workspace_targets"
}

if [ "${1:-}" = --select-one ]; then
	shift
	project_workspace_select_one "$@"
fi
