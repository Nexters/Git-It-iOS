# 공개 결과 상태와 안정 진단 token 정책입니다.

result_policy_exit_status() (
	result_policy_status=$1
	case "$result_policy_status" in
	succeeded | skipped) printf '0\n' ;;
	failed) printf '1\n' ;;
	interrupted) printf '130\n' ;;
	*) return 2 ;;
	esac
)

result_policy_signal_exit() (
	result_policy_signal=$1
	case "$result_policy_signal" in
	HUP) printf '129\n' ;;
	INT) printf '130\n' ;;
	TERM) printf '143\n' ;;
	*) return 2 ;;
	esac
)

result_policy_is_known_code() (
	result_policy_code=$1
	case "$result_policy_code" in
	common.invalid-input | common.missing-tool | common.version-mismatch | \
		common.outside-root | common.interrupted | \
		project-build.missing-workspace | project-build.no-schemes | \
		project-build.no-test-schemes | project-build.scheme-failed | \
		swift-format.no-targets | swift-format.formatter-failed | \
		swift-format.restage-required | commit-convention.message-invalid | \
		hook-management.install-failed | \
		pre-commit.step-failed | \
		script-tests.no-tests | script-tests.failed | \
		script-verification.static-failed | \
		script-verification.dependency-prepare-failed | \
		script-verification.dependency-invalid | \
		script-verification.regression-failed | \
		script-verification.architecture-incomplete) return 0 ;;
	*) return 1 ;;
	esac
)

result_policy_validate_diagnostic() (
	result_policy_feature=$1
	result_policy_operation=$2
	result_policy_target=$3
	result_policy_cause=$4
	result_policy_recovery=$5

	[ -n "$result_policy_feature" ] &&
		[ -n "$result_policy_operation" ] &&
		[ -n "$result_policy_target" ] &&
		[ -n "$result_policy_cause" ] &&
		[ -n "$result_policy_recovery" ] || return 2
)
