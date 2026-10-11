# 안전하게 가능한 모든 검증 단계를 fail-after-collect로 실행합니다.

verify_run() (
	verify_dependency=$1
	verify_static=$2
	verify_regression=$3
	verify_failures=0

	"$verify_dependency" || verify_failures=$((verify_failures + 1))
	"$verify_static" || verify_failures=$((verify_failures + 1))
	"$verify_regression" || verify_failures=$((verify_failures + 1))

	[ "$verify_failures" -eq 0 ]
)
