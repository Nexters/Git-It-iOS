#!/bin/sh
# shellcheck disable=SC1090,SC1091
# 시작할 수 있는 issue에서 feature/<번호>-<도메인>-<내용> 브랜치를 내고 전환합니다.

set -eu

start_branch_usage() (
	printf '조치: start-branch.sh <번호> --domain <도메인> --topic <내용> 형식으로 실행하세요\n' >&2
)

# 유스케이스의 token을 stderr 진단으로 옮깁니다.
start_branch_report() (
	start_branch_token=$1
	start_branch_value=$2
	start_branch_detail=${3:-}

	case "$start_branch_token" in
	missing-lane-table)
		printf '오류[issue-workflow.missing-lane-table]: %s에서 레인 표를 읽을 수 없습니다\n조치: 레인 표를 복원하세요\n' "$start_branch_value" >&2
		;;
	unknown-domain)
		printf "오류[issue-workflow.unknown-domain]: 도메인 '%s'은 레인 표에 없습니다\n조치: 다음 중 하나를 쓰세요: %s\n" \
			"$start_branch_value" "$(printf '%s\n' "$start_branch_detail" | tr '\n' ' ')" >&2
		;;
	invalid-topic)
		printf "오류[issue-workflow.invalid-topic]: --topic '%s'은 소문자 kebab-case여야 합니다\n" "$start_branch_value" >&2
		;;
	issue-state-unavailable)
		printf '오류[issue-workflow.issue-state-unavailable]: issue #%s의 상태를 확인할 수 없습니다\n조치: gh 인증과 네트워크를 확인하세요\n' "$start_branch_value" >&2
		;;
	issue-missing)
		printf '오류[issue-workflow.issue-missing]: issue #%s가 없습니다\n조치: 번호를 확인하세요\n' "$start_branch_value" >&2
		;;
	issue-closed)
		printf '오류[issue-workflow.issue-closed]: issue #%s는 닫혔습니다\n조치: 열린 issue에서 브랜치를 내세요\n' "$start_branch_value" >&2
		;;
	issue-held)
		printf "오류[issue-workflow.issue-held]: issue #%s에 '%s' 라벨이 있습니다\n조치: 지금 시작할 일이면 라벨을 뗀 뒤 다시 실행하세요\n" \
			"$start_branch_value" "$start_branch_detail" >&2
		;;
	issue-in-progress)
		printf "오류[issue-workflow.issue-in-progress]: issue #%s의 같은 레인 브랜치 '%s'가 남아 있습니다\n조치: 그 브랜치에서 이어 가거나, 머지되거나 지워진 뒤 다시 실행하세요\n" \
			"$start_branch_value" "$start_branch_detail" >&2
		;;
	esac
)

start_branch_main() (
	start_branch_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	start_branch_suite=$(CDPATH='' cd -- "$start_branch_bin/.." && pwd -P)
	start_branch_root=$(CDPATH='' cd -- "$start_branch_suite/../.." && pwd -P)
	start_branch_paths="$start_branch_root/.tools/repository-paths/bin/repository-paths.sh"
	. "$start_branch_suite/core/branch-policy.sh"
	. "$start_branch_suite/core/issue-policy.sh"
	. "$start_branch_suite/core/convention-reader.sh"
	. "$start_branch_suite/core/github-adapter.sh"
	. "$start_branch_suite/core/issue-gate.sh"
	. "$start_branch_suite/core/start-branch.sh"

	start_branch_number=''
	start_branch_domain=''
	start_branch_topic=''
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--domain | --topic)
			[ "$#" -ge 2 ] || {
				printf '오류[issue-workflow.invalid-input]: %s에 값이 필요합니다\n' "$1" >&2
				start_branch_usage
				return 2
			}
			if [ "$1" = --domain ]; then
				start_branch_domain=$2
			else
				start_branch_topic=$2
			fi
			shift 2
			;;
		-*)
			printf '오류[issue-workflow.invalid-input]: 알 수 없는 인자 %s\n' "$1" >&2
			start_branch_usage
			return 2
			;;
		*)
			start_branch_number=$1
			shift
			;;
		esac
	done

	case "$start_branch_number" in
	'' | 0 | *[!0-9]*)
		printf '오류[issue-workflow.invalid-issue-number]: issue 번호가 필요합니다\n' >&2
		start_branch_usage
		return 2
		;;
	esac
	start_branch_lane_doc=$("$start_branch_paths" --absolute GIT_IT_WORKFLOW_LANE_DOC) || return 1

	start_branch_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-start-branch.XXXXXX") || return 1
	trap 'rm -rf "$start_branch_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM

	start_branch_run "$start_branch_number" "$start_branch_domain" "$start_branch_topic" \
		"$start_branch_lane_doc" "$start_branch_work" \
		convention_reader_lanes github_adapter_issue_state github_adapter_issue_labels \
		github_adapter_linked_branches github_adapter_develop_branch start_branch_report
)

start_branch_main "$@"
