# GitHub Actions job 결과를 gate가 집계할 안정 token으로 변환합니다.

ci_gate_result_policy() (
	[ "$#" -eq 1 ] || return 2
	case "$1" in
	success) printf '%s\n' passed ;;
	skipped) printf '%s\n' skipped ;;
	failure | cancelled) printf '%s\n' failed ;;
	*) printf '%s\n' unknown ;;
	esac
)
