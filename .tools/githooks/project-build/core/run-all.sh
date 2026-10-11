# scheme 관찰과 Xcode action 실행 포트를 조합합니다.

project_run_all() (
	project_run_observe=$1
	project_run_execute=$2
	project_run_observed=$3
	project_run_targets=$4
	project_run_results=$5

	: >"$project_run_observed"
	: >"$project_run_targets"
	: >"$project_run_results"
	"$project_run_observe" "$project_run_observed" "$project_run_targets" || return 2
	[ -s "$project_run_targets" ] || return 0
	"$project_run_execute" "$project_run_targets" "$project_run_results"
)
