# 검증 단계 집계 정책입니다.

verification_policy_aggregate() (
	if [ "$1" -eq 0 ]; then
		printf 'skipped\n'
	elif [ "$2" -gt 0 ]; then
		printf 'failed\n'
	else
		printf 'succeeded\n'
	fi
)
