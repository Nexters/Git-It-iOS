# 공유 scheme 적격성, Xcode action과 실행 결과 집계 정책입니다.

scheme_policy_decide() (
	scheme_policy_projects_root=$1
	scheme_policy_workspace_root=$2
	scheme_policy_path=$3
	scheme_policy_scope=$4
	scheme_policy_has_tests=$5
	scheme_policy_name=$(basename -- "$scheme_policy_path" .xcscheme)

	case "$scheme_policy_path/" in
	"$scheme_policy_projects_root/"*/xcshareddata/xcschemes/*.xcscheme/ | \
		"$scheme_policy_workspace_root/xcshareddata/xcschemes/"*.xcscheme/) ;;
	*)
		printf 'ineligible\n'
		return 0
		;;
	esac

	case "$scheme_policy_scope:$scheme_policy_has_tests:$scheme_policy_name" in
	all:true:* | all:false:*) printf 'eligible\n' ;;
	app:*:App) printf 'eligible\n' ;;
	app:*:*) printf 'ineligible\n' ;;
	testable:true:AllTests) printf 'ineligible\n' ;;
	testable:true:*) printf 'eligible\n' ;;
	testable:false:*) printf 'ineligible\n' ;;
	# CI unit 검증은 workspace aggregate 한 번으로 공통 의존성을 재사용합니다.
	unit:true:AllTests) printf 'eligible\n' ;;
	unit:true:*) printf 'ineligible\n' ;;
	unit:false:*) printf 'ineligible\n' ;;
	ui:*:*) printf 'ineligible\n' ;;
	*) return 2 ;;
	esac
)

scheme_policy_xcode_action() (
	case "$1" in
	build | build-app) printf 'build\n' ;;
	compile | compile-unit | compile-ui) printf 'build-for-testing\n' ;;
	test | test-unit | test-ui) printf 'test-without-building\n' ;;
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
