# 전체 프로젝트 셸 회귀 테스트를 수집하고 실행하는 유스케이스입니다.

script_tests_run() (
	script_tests_root=$1
	script_tests_work=$2
	script_tests_collect_port=$3
	script_tests_execute_port=$4
	script_tests_list="$script_tests_work/tests.nul"
	mkdir -p "$script_tests_work" || return 2
	"$script_tests_collect_port" "$script_tests_root" "$script_tests_list" || return $?
	[ -s "$script_tests_list" ] || {
		printf '오류[script-tests.no-tests]: 실행할 스크립트 테스트가 없습니다\n조치: tools 아래에 tests/test-*.sh 테스트를 추가하세요\n' >&2
		return 2
	}
	if "$script_tests_execute_port" "$script_tests_list"; then
		printf '스크립트 테스트 완료\n'
	else
		script_tests_status=$?
		printf '오류[script-tests.failed]: 하나 이상의 스크립트 테스트가 실패했습니다\n조치: 위 테스트 출력을 확인해 실패 원인을 해결하세요\n' >&2
		return "$script_tests_status"
	fi
)
