#!/bin/sh
# shellcheck disable=SC1090,SC1091
# 브랜치의 issue가 시작할 수 있는 상태인지 확인하고 번호, 제목, 라벨과 본문을 출력합니다.

set -eu

read_issue_usage() (
	printf '조치: read-issue.sh [--branch <이름>] 형식으로 실행하세요\n' >&2
)

# 유스케이스의 token을 stderr 진단으로 옮깁니다.
read_issue_report() (
	read_issue_token=$1
	read_issue_value=$2
	read_issue_detail=${3:-}

	case "$read_issue_token" in
	missing-lane-table)
		printf '오류[issue-workflow.missing-lane-table]: %s에서 레인 표를 읽을 수 없습니다\n조치: 레인 표를 복원하세요\n' "$read_issue_value" >&2
		;;
	invalid-branch-name)
		printf "오류[issue-workflow.invalid-branch-name]: '%s'가 feature/<번호>-<도메인>-<내용> 형식이 아닙니다\n조치: /write-issue로 issue 브랜치를 내세요\n" "$read_issue_value" >&2
		;;
	issue-state-unavailable)
		printf '오류[issue-workflow.issue-state-unavailable]: issue #%s를 읽을 수 없습니다\n조치: gh 인증과 네트워크를 확인하세요\n' "$read_issue_value" >&2
		;;
	issue-missing)
		printf '오류[issue-workflow.issue-missing]: issue #%s가 없습니다\n조치: 브랜치 이름의 번호를 확인하세요\n' "$read_issue_value" >&2
		;;
	issue-closed)
		printf '오류[issue-workflow.issue-closed]: issue #%s는 닫혔습니다\n조치: 열린 issue에서 브랜치를 내세요\n' "$read_issue_value" >&2
		;;
	issue-held)
		printf "오류[issue-workflow.issue-held]: issue #%s에 '%s' 라벨이 있습니다\n조치: 지금 시작할 일이면 라벨을 뗀 뒤 다시 실행하세요\n" \
			"$read_issue_value" "$read_issue_detail" >&2
		;;
	esac
)

read_issue_main() (
	read_issue_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	read_issue_suite=$(CDPATH='' cd -- "$read_issue_bin/.." && pwd -P)
	read_issue_root=$(CDPATH='' cd -- "$read_issue_suite/../.." && pwd -P)
	read_issue_paths="$read_issue_root/.tools/repository-paths/bin/repository-paths.sh"
	. "$read_issue_suite/core/branch-policy.sh"
	. "$read_issue_suite/core/issue-policy.sh"
	. "$read_issue_suite/core/convention-reader.sh"
	. "$read_issue_suite/core/repository-adapter.sh"
	. "$read_issue_suite/core/github-adapter.sh"
	. "$read_issue_suite/core/issue-gate.sh"
	. "$read_issue_suite/core/read-issue.sh"

	# 브랜치를 지정하지 않으면 현재 브랜치를 읽습니다.
	read_issue_name=''
	read_issue_name_given=false
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--branch)
			[ "$#" -ge 2 ] || {
				printf '오류[issue-workflow.invalid-input]: %s에 값이 필요합니다\n' "$1" >&2
				read_issue_usage
				return 2
			}
			read_issue_name=$2
			read_issue_name_given=true
			shift 2
			;;
		*)
			printf '오류[issue-workflow.invalid-input]: 알 수 없는 인자 %s\n' "$1" >&2
			read_issue_usage
			return 2
			;;
		esac
	done

	read_issue_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-read-issue.XXXXXX") || return 1
	trap 'rm -rf "$read_issue_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM

	# git과 gh가 이 저장소를 보도록 루트에서 실행합니다.
	cd -- "$read_issue_root"
	read_issue_lane_doc=$("$read_issue_paths" GIT_IT_WORKFLOW_LANE_DOC) || return 1

	read_issue_run "$read_issue_name_given" "$read_issue_name" "$read_issue_lane_doc" "$read_issue_work" \
		convention_reader_lanes repository_adapter_current_branch github_adapter_issue_state \
		github_adapter_issue_labels github_adapter_issue_context read_issue_report
)

read_issue_main "$@"
