#!/bin/sh
# issue 제목 길이, 라벨 조합과 시작 가능 여부를 판정하는 순수 정책입니다.

# UTF-8 후속 바이트를 빼서 locale과 무관하게 글자 수를 셉니다.
issue_policy_title_length() (
	printf '%s' "$1" | LC_ALL=C tr -d '\200-\277' | wc -c | tr -d ' '
)

# 빈 줄과 중복 라벨을 지우고 입력 순서를 유지합니다.
issue_policy_unique_labels() (
	printf '%s\n' "$1" | awk 'NF && !seen[$0]++'
)

# 라벨 표에서 라벨의 카테고리를 찾습니다.
issue_policy_category_of() (
	issue_policy_known=$1
	issue_policy_label=$2
	issue_policy_tab=$(printf '\t')

	while IFS=$issue_policy_tab read -r issue_policy_category issue_policy_name _; do
		if [ "$issue_policy_name" = "$issue_policy_label" ]; then
			printf '%s\n' "$issue_policy_category"
			return 0
		fi
	done <<EOF
$issue_policy_known
EOF
	return 1
)

# 라벨 조합을 안정 token으로 출력합니다: ok, unknown:<라벨>, duplicate:<카테고리>, missing:<카테고리>
issue_policy_check_labels() (
	issue_policy_known=$1
	issue_policy_selected=$2
	issue_policy_used=''
	issue_policy_tab=$(printf '\t')

	# 표에 있는 라벨만 받고 카테고리마다 하나만 허용합니다.
	while IFS= read -r issue_policy_label; do
		[ -n "$issue_policy_label" ] || continue
		issue_policy_category=$(issue_policy_category_of "$issue_policy_known" "$issue_policy_label") || {
			printf 'unknown:%s\n' "$issue_policy_label"
			return 0
		}
		case " $issue_policy_used " in
		*" $issue_policy_category "*)
			printf 'duplicate:%s\n' "$issue_policy_category"
			return 0
			;;
		esac
		issue_policy_used="$issue_policy_used $issue_policy_category"
	done <<EOF
$issue_policy_selected
EOF

	# 필수 카테고리가 모두 있어야 합니다.
	while IFS=$issue_policy_tab read -r issue_policy_category _ issue_policy_required; do
		[ "$issue_policy_required" = required ] || continue
		case " $issue_policy_used " in
		*" $issue_policy_category "*) ;;
		*)
			printf 'missing:%s\n' "$issue_policy_category"
			return 0
			;;
		esac
	done <<EOF
$issue_policy_known
EOF
	printf 'ok\n'
)

# 지금 시작하면 안 되는 issue의 status: 라벨을 출력합니다. 없으면 아무것도 출력하지 않습니다.
issue_policy_hold_label() (
	printf '%s\n' "$1" | awk '/^status: / { print; exit }'
)
