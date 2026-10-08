# Git porcelain 문자를 실행 환경 중립 상태 token으로 변환합니다.

git_status_policy_index() (
	git_status_index=$1
	case "$git_status_index" in
	A) printf 'added\n' ;;
	C) printf 'copied\n' ;;
	M) printf 'modified\n' ;;
	R) printf 'renamed\n' ;;
	D) printf 'deleted\n' ;;
	' ' | '?' | '!') printf 'none\n' ;;
	*) printf 'other\n' ;;
	esac
)

git_status_policy_worktree() (
	git_status_worktree=$1
	git_status_index=${2:- }
	if [ "$git_status_index$git_status_worktree" = '??' ]; then
		printf 'untracked\n'
		return 0
	fi

	case "$git_status_worktree" in
	M) printf 'modified\n' ;;
	D) printf 'deleted\n' ;;
	' ' | '!') printf 'clean\n' ;;
	*) printf 'other\n' ;;
	esac
)

git_status_policy_is_changed() (
	git_status_index=$1
	git_status_worktree=$2
	case "$git_status_index$git_status_worktree" in
	'  ' | '!!') printf 'false\n' ;;
	*) printf 'true\n' ;;
	esac
)

git_status_policy_is_staged_candidate() (
	git_status_index=$1
	case "$git_status_index" in
	A | C | M | R) printf 'true\n' ;;
	*) printf 'false\n' ;;
	esac
)
