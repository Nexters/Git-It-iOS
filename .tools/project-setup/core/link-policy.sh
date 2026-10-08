#!/bin/sh
# 심볼릭 링크 위치의 현재 상태를 생성·교체·충돌 결정으로 변환합니다.

project_setup_link_policy_decide() (
	project_setup_link_state=$1
	case "$project_setup_link_state" in
	absent) printf 'create\n' ;;
	symlink) printf 'replace\n' ;;
	file | directory) printf 'conflict\n' ;;
	*) return 2 ;;
	esac
)
