# 공유 scheme 적격성, Xcode action과 실행 결과 집계 정책입니다.

scheme_policy_decide() (
	scheme_policy_projects_root=$1
	scheme_policy_path=$2
	scheme_policy_scope=$3
	scheme_policy_has_tests=$4

	case "$scheme_policy_path/" in
	"$scheme_policy_projects_root/"*/xcshareddata/xcschemes/*.xcscheme/ | \
		*"/GitIt.xcworkspace/xcshareddata/xcschemes/"*.xcscheme/) ;;
	*)
		printf 'ineligible\n'
		return 0
		;;
	esac

	case "$scheme_policy_scope:$scheme_policy_has_tests" in
	all:true | all:false | testable:true) printf 'eligible\n' ;;
	testable:false) printf 'ineligible\n' ;;
	*) return 2 ;;
	esac
)

scheme_policy_xcode_action() (
	case "$1" in
	build) printf 'build\n' ;;
	compile) printf 'build-for-testing\n' ;;
	test) printf 'test-without-building\n' ;;
	*) return 2 ;;
	esac
)

scheme_policy_aggregate() (
	scheme_policy_total=$1
	scheme_policy_failed=$2
	if [ "$scheme_policy_total" -eq 0 ]; then
		printf 'skipped\n'
	elif [ "$scheme_policy_failed" -gt 0 ]; then
		printf 'failed\n'
	else
		printf 'succeeded\n'
	fi
)
