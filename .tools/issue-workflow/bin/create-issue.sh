#!/bin/sh
# shellcheck disable=SC1090,SC1091
# 목적 문장과 라벨을 검사한 뒤 템플릿으로 issue를 만듭니다.

set -eu

create_issue_usage() (
	printf '조치: create-issue.sh --title <목적 문장> --label <라벨> ... [--template task|mismatch] [--body-file <경로>] 형식으로 실행하세요\n' >&2
)

create_issue_main() (
	create_issue_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	create_issue_suite=$(CDPATH='' cd -- "$create_issue_bin/.." && pwd -P)
	create_issue_root=$(CDPATH='' cd -- "$create_issue_suite/../.." && pwd -P)
	create_issue_paths="$create_issue_root/.tools/repository-paths/bin/repository-paths.sh"
	create_issue_title_limit=50
	. "$create_issue_suite/core/issue-policy.sh"
	. "$create_issue_suite/core/convention-reader.sh"
	. "$create_issue_suite/core/github-adapter.sh"

	create_issue_title=''
	create_issue_labels=''
	create_issue_template=task
	create_issue_body_file=''
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--title | --label | --template | --body-file)
			[ "$#" -ge 2 ] || {
				printf '오류[issue-workflow.invalid-input]: %s에 값이 필요합니다\n' "$1" >&2
				create_issue_usage
				return 2
			}
			case "$1" in
			--title) create_issue_title=$2 ;;
			--label) create_issue_labels="$create_issue_labels
$2" ;;
			--template) create_issue_template=$2 ;;
			--body-file) create_issue_body_file=$2 ;;
			esac
			shift 2
			;;
		*)
			printf '오류[issue-workflow.invalid-input]: 알 수 없는 인자 %s\n' "$1" >&2
			create_issue_usage
			return 2
			;;
		esac
	done

	# 제목은 목적 한 문장이며 글자 수는 공백을 포함해 셉니다.
	[ -n "$create_issue_title" ] || {
		printf '오류[issue-workflow.missing-title]: --title <목적 문장>이 필요합니다\n' >&2
		create_issue_usage
		return 2
	}
	create_issue_length=$(issue_policy_title_length "$create_issue_title")
	[ "$create_issue_length" -le "$create_issue_title_limit" ] || {
		printf '오류[issue-workflow.title-too-long]: 제목이 %s자입니다\n조치: 목적 문장을 공백 포함 %s자 이내로 줄이세요\n' \
			"$create_issue_length" "$create_issue_title_limit" >&2
		return 2
	}

	create_issue_template_root=$("$create_issue_paths" --absolute GIT_IT_ISSUE_TEMPLATE_ROOT) || return 1
	create_issue_template_file="$create_issue_template_root/$create_issue_template.md"
	case "$create_issue_template" in
	'' | */*) create_issue_template_file='' ;;
	esac
	[ -f "$create_issue_template_file" ] || {
		printf '오류[issue-workflow.unknown-template]: 템플릿 %s이 없습니다\n' "$create_issue_template" >&2
		create_issue_usage
		return 2
	}

	# 템플릿 기본 라벨과 입력 라벨을 합쳐 라벨 표로 검사합니다.
	create_issue_label_doc=$("$create_issue_paths" --absolute GIT_IT_WORKFLOW_LABEL_DOC) || return 1
	create_issue_known=$(convention_reader_labels "$create_issue_label_doc") || {
		printf '오류[issue-workflow.missing-label-table]: %s에서 라벨 표를 읽을 수 없습니다\n조치: 라벨 표를 복원하세요\n' "$create_issue_label_doc" >&2
		return 1
	}
	create_issue_template_labels=$(convention_reader_template_labels "$create_issue_template_file")
	create_issue_selected=$(issue_policy_unique_labels "$create_issue_template_labels
$create_issue_labels")
	create_issue_check=$(issue_policy_check_labels "$create_issue_known" "$create_issue_selected")
	case "$create_issue_check" in
	ok) ;;
	unknown:*)
		printf "오류[issue-workflow.unknown-label]: 라벨 '%s'은 라벨 표에 없습니다\n조치: %s의 라벨을 쓰세요\n" \
			"${create_issue_check#unknown:}" "$create_issue_label_doc" >&2
		return 2
		;;
	duplicate:*)
		printf "오류[issue-workflow.duplicate-label]: '%s' 카테고리의 라벨은 하나만 답니다\n" "${create_issue_check#duplicate:}" >&2
		return 2
		;;
	missing:*)
		printf "오류[issue-workflow.missing-label]: '%s' 카테고리 라벨이 필요합니다\n조치: --label로 그 카테고리의 라벨을 지정하세요\n" \
			"${create_issue_check#missing:}" >&2
		return 2
		;;
	esac

	create_issue_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-create-issue.XXXXXX") || return 1
	trap 'rm -rf "$create_issue_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM

	# 본문 파일이 없으면 템플릿 본문의 목적 절을 제목으로 채웁니다.
	create_issue_body="$create_issue_work/body.md"
	if [ -n "$create_issue_body_file" ]; then
		[ -f "$create_issue_body_file" ] || {
			printf '오류[issue-workflow.missing-body-file]: %s이 없습니다\n' "$create_issue_body_file" >&2
			return 2
		}
		cp -- "$create_issue_body_file" "$create_issue_body"
	else
		convention_reader_template_body "$create_issue_template_file" >"$create_issue_work/template.md"
		convention_reader_fill_purpose "$create_issue_work/template.md" "$create_issue_title" >"$create_issue_body"
	fi

	github_adapter_create_issue "$create_issue_title" "$create_issue_body" "$create_issue_selected"
)

create_issue_main "$@"
