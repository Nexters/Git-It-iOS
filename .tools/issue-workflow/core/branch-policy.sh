#!/bin/sh
# 브랜치 이름, 레인과 issue 상태로 편집 허용 여부를 정하는 순수 정책입니다.

# 내용 구간이 소문자 kebab-case인지 판정합니다.
branch_policy_is_topic() (
	LC_ALL=C
	case "$1" in
	'' | -* | *- | *--* | *[!a-z0-9-]*) return 1 ;;
	esac
)

# 레인 행에서 도메인 목록을 뽑습니다.
branch_policy_domains() (
	printf '%s\n' "$1" | cut -f1 | sort -u
)

# 도메인이 목록에 있는지 판정합니다.
branch_policy_has_domain() (
	for branch_policy_domain in $2; do
		[ "$branch_policy_domain" != "$1" ] || return 0
	done
	return 1
)

# feature/<번호>-<도메인>-<내용>을 "번호 도메인 내용"으로 나눕니다.
branch_policy_parse() (
	branch_policy_name=$1
	branch_policy_domain_list=$2

	case "$branch_policy_name" in
	feature/*) branch_policy_rest=${branch_policy_name#feature/} ;;
	*) return 1 ;;
	esac
	branch_policy_number=${branch_policy_rest%%-*}
	case "$branch_policy_number" in
	'' | *[!0-9]*) return 1 ;;
	esac
	branch_policy_rest=${branch_policy_rest#"$branch_policy_number"-}

	# 도메인은 레인 표의 값만 인정합니다.
	for branch_policy_domain in $branch_policy_domain_list; do
		case "$branch_policy_rest" in
		"$branch_policy_domain"-*)
			branch_policy_topic=${branch_policy_rest#"$branch_policy_domain"-}
			branch_policy_is_topic "$branch_policy_topic" || return 1
			printf '%s %s %s\n' "$branch_policy_number" "$branch_policy_domain" "$branch_policy_topic"
			return 0
			;;
		esac
	done
	return 1
)

# 연결 브랜치 중 같은 레인에서 진행 중인 첫 브랜치를 출력합니다. 없으면 아무것도 출력하지 않습니다.
branch_policy_active_branch() (
	branch_policy_linked=$1
	branch_policy_own=$2
	branch_policy_domain_list=$3

	while IFS= read -r branch_policy_branch; do
		[ -n "$branch_policy_branch" ] || continue

		# 이름을 해석할 수 없으면 레인을 알 수 없으므로 같은 레인으로 봅니다.
		if branch_policy_parsed=$(branch_policy_parse "$branch_policy_branch" "$branch_policy_domain_list"); then
			branch_policy_domain=${branch_policy_parsed#* }
			[ "${branch_policy_domain%% *}" = "$branch_policy_own" ] || continue
		fi
		printf '%s\n' "$branch_policy_branch"
		return 0
	done <<EOF
$branch_policy_linked
EOF
)

# 파일이 속한 레인의 도메인을 출력합니다. 여러 경로에 걸리면 가장 긴 경로가 이깁니다.
branch_policy_lane_of() (
	branch_policy_file=$1
	branch_policy_lanes=$2
	branch_policy_best=''
	branch_policy_best_length=0
	branch_policy_tab=$(printf '\t')

	while IFS=$branch_policy_tab read -r branch_policy_domain branch_policy_path; do
		case "$branch_policy_path" in
		'') continue ;;
		*/)
			case "$branch_policy_file" in
			"$branch_policy_path"*) ;;
			*) continue ;;
			esac
			;;
		*)
			[ "$branch_policy_file" = "$branch_policy_path" ] || continue
			;;
		esac
		if [ "${#branch_policy_path}" -gt "$branch_policy_best_length" ]; then
			branch_policy_best=$branch_policy_domain
			branch_policy_best_length=${#branch_policy_path}
		fi
	done <<EOF
$branch_policy_lanes
EOF
	printf '%s\n' "$branch_policy_best"
)

# 편집 허용 여부를 안정 token으로 출력합니다.
# allow, detached, protected, invalid-name, issue-missing, issue-closed, lane:<도메인>
branch_policy_decide() (
	branch_policy_name=$1
	branch_policy_lanes=$2
	branch_policy_issue_state=$3
	branch_policy_file=$4

	# Git-flow 브랜치의 규칙은 Constitution이 소유하므로 issue를 요구하지 않습니다.
	case "$branch_policy_name" in
	'')
		printf 'detached\n'
		return 0
		;;
	main | develop)
		printf 'protected\n'
		return 0
		;;
	hotfix/* | release/*)
		printf 'allow\n'
		return 0
		;;
	esac

	branch_policy_domain_list=$(branch_policy_domains "$branch_policy_lanes")
	branch_policy_parsed=$(branch_policy_parse "$branch_policy_name" "$branch_policy_domain_list") || {
		printf 'invalid-name\n'
		return 0
	}

	# issue 상태를 확인하지 못한 UNKNOWN은 막지 않고 레인 검사로 넘어갑니다.
	case "$branch_policy_issue_state" in
	MISSING)
		printf 'issue-missing\n'
		return 0
		;;
	CLOSED)
		printf 'issue-closed\n'
		return 0
		;;
	esac

	# 어느 레인에도 없는 파일은 어느 브랜치에서든 고칠 수 있습니다.
	branch_policy_own=${branch_policy_parsed#* }
	branch_policy_own=${branch_policy_own%% *}
	branch_policy_owner=''
	if [ -n "$branch_policy_file" ]; then
		branch_policy_owner=$(branch_policy_lane_of "$branch_policy_file" "$branch_policy_lanes")
	fi
	if [ -n "$branch_policy_owner" ] && [ "$branch_policy_owner" != "$branch_policy_own" ]; then
		printf 'lane:%s\n' "$branch_policy_owner"
		return 0
	fi
	printf 'allow\n'
)
