#!/bin/sh
# gh로 issue를 조회·생성하고 issue에 연결된 브랜치를 내는 GitHub 어댑터입니다.

# issue 상태를 OPEN, CLOSED, MISSING으로 출력합니다. gh 자체가 실패하면 실패합니다.
github_adapter_issue_state() (
	github_adapter_number=$1
	github_adapter_work=$2

	# gh는 PR 번호도 조회하므로 URL로 구분해 PR은 issue가 없는 것으로 봅니다.
	if gh issue view "$github_adapter_number" --json state,url -q '.state + " " + .url' \
		>"$github_adapter_work/issue-state" 2>"$github_adapter_work/issue-error"; then
		case "$(cat "$github_adapter_work/issue-state")" in
		*/pull/*) printf 'MISSING\n' ;;
		'OPEN '*) printf 'OPEN\n' ;;
		*) printf 'CLOSED\n' ;;
		esac
		return 0
	fi

	# 저장소 조회 실패와 구분되도록 issue 부재를 뜻하는 문구만 MISSING으로 봅니다.
	if grep -qi 'could not resolve to an issue' "$github_adapter_work/issue-error"; then
		printf 'MISSING\n'
		return 0
	fi
	cat "$github_adapter_work/issue-error" >&2
	return 1
)

# 같은 저장소·브랜치의 issue 상태를 10분간 재사용해 편집마다 gh를 부르지 않습니다.
github_adapter_cached_issue_state() (
	github_adapter_root=$1
	github_adapter_branch=$2
	github_adapter_number=$3
	github_adapter_work=$4
	github_adapter_cache="${TMPDIR:-/tmp}/git-it-issue-workflow"
	github_adapter_key=$(printf '%s\n%s\n' "$github_adapter_root" "$github_adapter_branch" | cksum | tr ' ' '-')
	github_adapter_file="$github_adapter_cache/$github_adapter_key"

	if [ -f "$github_adapter_file" ] && [ -n "$(find "$github_adapter_file" -mmin -10 2>/dev/null)" ]; then
		cat "$github_adapter_file"
		return 0
	fi
	github_adapter_state=$(github_adapter_issue_state "$github_adapter_number" "$github_adapter_work") || return 1
	mkdir -p "$github_adapter_cache"
	printf '%s\n' "$github_adapter_state" >"$github_adapter_file"
	printf '%s\n' "$github_adapter_state"
)

# issue의 라벨을 한 줄에 하나씩 출력합니다.
github_adapter_issue_labels() (
	gh issue view "$1" --json labels -q '.labels[].name'
)

# issue에 연결된 브랜치를 한 줄에 하나씩 출력합니다. 머지로 지워진 브랜치는 나오지 않습니다.
github_adapter_linked_branches() (
	gh issue develop --list "$1" >"$2/linked-branches" || return 1
	cut -f1 "$2/linked-branches"
)

# issue를 만들고 그 URL을 출력합니다.
github_adapter_create_issue() (
	github_adapter_title=$1
	github_adapter_body=$2
	github_adapter_labels=$3

	set -- issue create --title "$github_adapter_title" --body-file "$github_adapter_body"
	while IFS= read -r github_adapter_label; do
		[ -n "$github_adapter_label" ] || continue
		set -- "$@" --label "$github_adapter_label"
	done <<EOF
$github_adapter_labels
EOF
	gh "$@"
)

# issue에 연결된 브랜치를 develop에서 내고 전환합니다.
github_adapter_develop_branch() (
	gh issue develop "$1" --name "$2" --base develop --checkout
)
