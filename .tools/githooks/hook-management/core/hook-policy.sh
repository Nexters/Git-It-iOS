# 현재 저장소의 local hook 설정과 executable 정책입니다.

hook_policy_validate_config() (
	if [ "$1" = "$2" ]; then printf 'valid\n'; else printf 'invalid\n'; fi
)

hook_policy_validate_executable() (
	if [ "$1" = true ]; then printf 'valid\n'; else printf 'invalid\n'; fi
)
