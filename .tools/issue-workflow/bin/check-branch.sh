#!/bin/sh
# shellcheck disable=SC1090,SC1091
# 편집 전 hook입니다. 열린 issue의 feature 브랜치가 아니거나 다른 레인의 경로면 편집을 막습니다.

set -eu

# 정책 token을 stderr 진단으로 옮깁니다.
check_branch_report() (
	check_branch_verdict=$1
	check_branch_name=$2
	check_branch_target=$3
	check_branch_lane_doc=$4

	case "$check_branch_verdict" in
	detached)
		printf '오류[issue-workflow.detached-head]: HEAD가 브랜치에 있지 않습니다\n' >&2
		;;
	protected)
		printf "오류[issue-workflow.protected-branch]: '%s'는 보호 브랜치입니다\n" "$check_branch_name" >&2
		;;
	invalid-name)
		printf "오류[issue-workflow.invalid-branch-name]: '%s'가 feature/<번호>-<도메인>-<내용> 형식이 아닙니다\n" \
			"$check_branch_name" >&2
		;;
	issue-missing)
		printf "오류[issue-workflow.issue-missing]: '%s'의 issue가 없습니다\n" "$check_branch_name" >&2
		;;
	issue-closed)
		printf "오류[issue-workflow.issue-closed]: '%s'의 issue가 닫혔습니다\n" "$check_branch_name" >&2
		;;
	lane:*)
		printf "오류[issue-workflow.lane-mismatch]: '%s'는 %s 레인의 경로입니다\n조치: 그 레인의 브랜치에서 따로 하세요(%s)\n" \
			"$check_branch_target" "${check_branch_verdict#lane:}" "$check_branch_lane_doc" >&2
		return 0
		;;
	esac
	printf '조치: 열린 issue에서 브랜치를 내세요(/start-work 또는 start-branch.sh <번호> --domain <도메인> --topic <내용>)\n' >&2
)

check_branch_main() (
	check_branch_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	check_branch_suite=$(CDPATH='' cd -- "$check_branch_bin/.." && pwd -P)
	check_branch_root=$(CDPATH='' cd -- "$check_branch_suite/../.." && pwd -P)
	check_branch_paths="$check_branch_root/.tools/repository-paths/bin/repository-paths.sh"
	. "$check_branch_suite/core/branch-policy.sh"
	. "$check_branch_suite/core/convention-reader.sh"
	. "$check_branch_suite/core/repository-adapter.sh"
	. "$check_branch_suite/core/github-adapter.sh"

	# 손으로 돌릴 때만 인자를 받고, hook은 stdin JSON으로 대상을 넘깁니다.
	check_branch_name=''
	check_branch_name_given=false
	check_branch_file=''
	check_branch_file_given=false
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--branch | --file)
			[ "$#" -ge 2 ] || {
				printf '오류[issue-workflow.invalid-input]: %s에 값이 필요합니다\n조치: check-branch.sh [--branch <이름>] [--file <경로>] 형식으로 실행하세요\n' "$1" >&2
				return 2
			}
			if [ "$1" = --branch ]; then
				check_branch_name=$2
				check_branch_name_given=true
			else
				check_branch_file=$2
				check_branch_file_given=true
			fi
			shift 2
			;;
		*)
			printf '오류[issue-workflow.invalid-input]: 알 수 없는 인자 %s\n조치: check-branch.sh [--branch <이름>] [--file <경로>] 형식으로 실행하세요\n' "$1" >&2
			return 2
			;;
		esac
	done

	check_branch_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-check-branch.XXXXXX") || return 1
	trap 'rm -rf "$check_branch_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM

	if [ "$check_branch_name_given" = false ] && [ "$check_branch_file_given" = false ] && [ ! -t 0 ]; then
		cat >"$check_branch_work/input"
		check_branch_file=$(repository_adapter_tool_file "$check_branch_work/input") || check_branch_file=''
	fi
	cd -- "$check_branch_root"

	# 저장소 밖과 Git이 무시하는 파일은 규칙 대상이 아닙니다.
	check_branch_relative=''
	if [ -n "$check_branch_file" ]; then
		check_branch_relative=$(repository_adapter_relative_path "$check_branch_root" "$check_branch_file") || return 0
		if repository_adapter_is_ignored "$check_branch_relative"; then
			return 0
		fi
	fi

	check_branch_lane_doc=$("$check_branch_paths" GIT_IT_WORKFLOW_LANE_DOC) || return 1
	check_branch_lanes=$(convention_reader_lanes "$check_branch_lane_doc") || {
		printf '오류[issue-workflow.missing-lane-table]: %s에서 레인 표를 읽을 수 없습니다\n조치: 레인 표를 복원하세요\n' "$check_branch_lane_doc" >&2
		return 1
	}
	if [ "$check_branch_name_given" = false ]; then
		check_branch_name=$(repository_adapter_current_branch) || return 1
	fi

	# gh가 실패해도 편집을 멈추지 않도록 상태를 UNKNOWN으로 두고 레인만 검사합니다.
	check_branch_state=''
	check_branch_domains=$(branch_policy_domains "$check_branch_lanes")
	if check_branch_parsed=$(branch_policy_parse "$check_branch_name" "$check_branch_domains"); then
		check_branch_state=$(github_adapter_cached_issue_state "$check_branch_root" "$check_branch_name" \
			"${check_branch_parsed%% *}" "$check_branch_work") || {
			printf '경고[issue-workflow.issue-state-unavailable]: issue 상태를 확인하지 못해 막지 않습니다\n' >&2
			check_branch_state=UNKNOWN
		}
	fi

	check_branch_verdict=$(branch_policy_decide "$check_branch_name" "$check_branch_lanes" \
		"$check_branch_state" "$check_branch_relative")
	[ "$check_branch_verdict" != allow ] || return 0
	check_branch_report "$check_branch_verdict" "$check_branch_name" "$check_branch_relative" "$check_branch_lane_doc"
	return 2
)

check_branch_main "$@"
