#!/bin/sh
# shellcheck disable=SC1090,SC1091
# 실제 gh로 issue 작업 흐름의 공개 명령을 실행해 판정과 소요 시간을 잽니다.
# 브랜치는 내지 않습니다. --label-probe를 주면 issue에 status: 라벨을 잠깐 달았다가 뗍니다.

set -eu

measure_flow_usage() (
	printf '조치: measure-flow.sh --branch <이름> [--repeat <횟수>] [--label-probe] [--summary <파일>] 형식으로 실행하세요\n' >&2
)

# 유스케이스의 token을 stderr 진단으로 옮깁니다.
measure_flow_report() (
	case "$1" in
	measure-mismatch)
		printf "오류[issue-workflow.measure-mismatch]: '%s'가 exit %s로 끝났습니다(기대 %s)\n조치: 아래 출력으로 판정이 바뀐 이유를 확인하세요\n" \
			"$2" "$3" "$4" >&2
		cat "$5" >&2
		;;
	measure-over-budget)
		printf "오류[issue-workflow.measure-over-budget]: '%s'의 중앙값 %sms가 예산 %sms를 넘었습니다\n조치: gh 호출이 늘었는지 확인하세요\n" \
			"$2" "$3" "$4" >&2
		;;
	esac
)

# 현재 시각을 밀리초로 출력합니다.
measure_flow_clock() (
	perl -MTime::HiRes=time -e 'printf "%d\n", time() * 1000'
)

# 아래 함수는 main이 정한 값으로 공개 명령 하나를 실행합니다.
measure_flow_gh_once() (
	github_adapter_issue_state "$measure_flow_number" "$measure_flow_work"
)

measure_flow_edit_cold() (
	rm -rf "$measure_flow_cache/git-it-issue-workflow"
	TMPDIR=$measure_flow_cache "$measure_flow_bin/check-branch.sh" --branch "$measure_flow_name"
)

measure_flow_edit_warm() (
	TMPDIR=$measure_flow_cache "$measure_flow_bin/check-branch.sh" --branch "$measure_flow_name"
)

measure_flow_read() (
	"$measure_flow_bin/read-issue.sh" --branch "$measure_flow_name"
)

measure_flow_start() (
	"$measure_flow_bin/start-branch.sh" "$measure_flow_number" --domain "$1" --topic ci-probe --check
)

measure_flow_start_denied() (
	GH_TOKEN=invalid "$measure_flow_bin/start-branch.sh" "$measure_flow_number" --domain "$1" --topic ci-probe --check
)

# 표 한 행을 잽니다. 실패해도 남은 행을 계속 잽니다.
measure_flow_row() {
	measure_flow_row_label=$1
	measure_flow_row_status=$2
	measure_flow_row_code=$3
	measure_flow_row_budget=$(measure_policy_budget "$measure_flow_baseline" "$4")
	shift 4
	measure_flow_sample "$measure_flow_row_label" "$measure_flow_row_status" "$measure_flow_row_code" \
		"$measure_flow_repeat" "$measure_flow_row_budget" "$measure_flow_work" \
		measure_flow_clock measure_flow_report "$@" >>"$measure_flow_work/rows" || measure_flow_failed=true
}

# 달아 둔 라벨을 뗍니다. 떼지 못하면 사람이 뗄 수 있게 알립니다.
measure_flow_release_label() {
	[ "$measure_flow_label_added" = true ] || return 0
	measure_flow_label_added=false
	github_adapter_remove_label "$measure_flow_number" "$measure_flow_hold" || {
		printf "오류[issue-workflow.label-left]: issue #%s에서 '%s' 라벨을 떼지 못했습니다\n조치: 라벨을 직접 뗀 뒤 다시 실행하세요\n" \
			"$measure_flow_number" "$measure_flow_hold" >&2
		return 1
	}
}

# status: 라벨을 달아 실제 차단을 재고 뗍니다.
measure_flow_probe_label() {
	measure_flow_labels=$(convention_reader_labels "$measure_flow_label_doc") || measure_flow_labels=''
	measure_flow_hold=$(issue_policy_hold_label "$(printf '%s\n' "$measure_flow_labels" | cut -f2)")
	if [ -z "$measure_flow_hold" ] || ! github_adapter_add_label "$measure_flow_number" "$measure_flow_hold"; then
		printf "오류[issue-workflow.label-write-failed]: issue #%s에 status: 라벨을 달지 못했습니다\n조치: 라벨 표와 gh의 issues 쓰기 권한을 확인하세요\n" \
			"$measure_flow_number" >&2
		measure_flow_failed=true
		return 0
	fi
	measure_flow_label_added=true

	measure_flow_row 'status: 라벨 차단, 브랜치 시작' 2 issue-held 2 measure_flow_start "$measure_flow_domain"
	measure_flow_row 'status: 라벨 차단, 문맥 읽기' 2 issue-held 2 measure_flow_read
	measure_flow_release_label || measure_flow_failed=true
}

measure_flow_main() (
	measure_flow_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	measure_flow_suite=$(CDPATH='' cd -- "$measure_flow_bin/.." && pwd -P)
	measure_flow_root=$(CDPATH='' cd -- "$measure_flow_suite/../.." && pwd -P)
	measure_flow_paths="$measure_flow_root/.tools/repository-paths/bin/repository-paths.sh"
	. "$measure_flow_suite/core/branch-policy.sh"
	. "$measure_flow_suite/core/issue-policy.sh"
	. "$measure_flow_suite/core/convention-reader.sh"
	. "$measure_flow_suite/core/github-adapter.sh"
	. "$measure_flow_suite/core/measure-policy.sh"
	. "$measure_flow_suite/core/measure-flow.sh"

	measure_flow_name=''
	measure_flow_repeat=5
	measure_flow_with_label=false
	measure_flow_summary=''
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--label-probe)
			measure_flow_with_label=true
			shift
			;;
		--branch | --repeat | --summary)
			[ "$#" -ge 2 ] || {
				printf '오류[issue-workflow.invalid-input]: %s에 값이 필요합니다\n' "$1" >&2
				measure_flow_usage
				return 2
			}
			case "$1" in
			--branch) measure_flow_name=$2 ;;
			--repeat) measure_flow_repeat=$2 ;;
			*) measure_flow_summary=$2 ;;
			esac
			shift 2
			;;
		*)
			printf '오류[issue-workflow.invalid-input]: 알 수 없는 인자 %s\n' "$1" >&2
			measure_flow_usage
			return 2
			;;
		esac
	done

	[ -n "$measure_flow_name" ] || {
		printf '오류[issue-workflow.invalid-input]: --branch가 필요합니다\n' >&2
		measure_flow_usage
		return 2
	}
	case "$measure_flow_repeat" in
	'' | 0 | *[!0-9]*)
		printf '오류[issue-workflow.invalid-input]: --repeat는 1 이상의 정수여야 합니다\n' >&2
		measure_flow_usage
		return 2
		;;
	esac

	measure_flow_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-measure-flow.XXXXXX") || return 1
	measure_flow_cache="$measure_flow_work/cache"
	mkdir "$measure_flow_cache"
	measure_flow_label_added=false
	trap 'measure_flow_release_label || :; rm -rf "$measure_flow_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM

	# gh가 이 저장소를 보도록 루트에서 실행하고, 브랜치 이름에서 issue와 레인을 얻습니다.
	cd -- "$measure_flow_root"
	measure_flow_lane_doc=$("$measure_flow_paths" GIT_IT_WORKFLOW_LANE_DOC) || return 1
	measure_flow_label_doc=$("$measure_flow_paths" GIT_IT_WORKFLOW_LABEL_DOC) || return 1
	measure_flow_lanes=$(convention_reader_lanes "$measure_flow_lane_doc") || {
		printf '오류[issue-workflow.missing-lane-table]: %s에서 레인 표를 읽을 수 없습니다\n조치: 레인 표를 복원하세요\n' "$measure_flow_lane_doc" >&2
		return 1
	}
	measure_flow_domains=$(branch_policy_domains "$measure_flow_lanes")
	measure_flow_parsed=$(branch_policy_parse "$measure_flow_name" "$measure_flow_domains") || {
		printf "오류[issue-workflow.invalid-branch-name]: '%s'가 feature/<번호>-<도메인>-<내용> 형식이 아닙니다\n조치: issue 브랜치를 지정하세요\n" "$measure_flow_name" >&2
		return 2
	}
	measure_flow_number=${measure_flow_parsed%% *}
	measure_flow_domain=${measure_flow_parsed#* }
	measure_flow_domain=${measure_flow_domain%% *}

	# 다른 레인 통과를 확인할 도메인을 고릅니다.
	measure_flow_other=''
	for measure_flow_candidate in $measure_flow_domains; do
		[ "$measure_flow_candidate" = "$measure_flow_domain" ] || measure_flow_other=$measure_flow_candidate
	done

	# gh 호출 1회의 시간을 먼저 재서 명령별 예산의 기준으로 씁니다.
	measure_flow_failed=false
	: >"$measure_flow_work/rows"
	measure_flow_sample 'gh 조회 1회(기준)' 0 '' "$measure_flow_repeat" 0 "$measure_flow_work" \
		measure_flow_clock measure_flow_report measure_flow_gh_once >>"$measure_flow_work/rows" || measure_flow_failed=true
	measure_flow_baseline=$(cat "$measure_flow_work/sample-median")

	# 네 번째 값은 그 명령이 부르는 gh 호출 수입니다.
	measure_flow_row '편집 전 검사, 캐시 없음' 0 '' 1 measure_flow_edit_cold
	measure_flow_row '편집 전 검사, 캐시 있음' 0 '' 0 measure_flow_edit_warm
	measure_flow_row 'issue 문맥 읽기' 0 '' 3 measure_flow_read
	measure_flow_row '같은 레인 차단' 2 issue-in-progress 3 measure_flow_start "$measure_flow_domain"
	measure_flow_row '다른 레인 통과' 0 '' 3 measure_flow_start "$measure_flow_other"
	measure_flow_row 'gh 인증 실패 차단' 1 issue-state-unavailable 1 measure_flow_start_denied "$measure_flow_domain"

	# 읽기만 하는 판정이 맞을 때만 GitHub에 씁니다.
	if [ "$measure_flow_with_label" = true ] && [ "$measure_flow_failed" = false ]; then
		measure_flow_probe_label
	fi

	# 표를 출력하고, 지정한 파일에도 더합니다.
	{
		printf '## issue 작업 흐름 측정\n\n브랜치 %s, 반복 %s회\n\n' "$measure_flow_name" "$measure_flow_repeat"
		printf '| 단계 | 기대 | 결과 | 횟수 | 중앙값(ms) | 최댓값(ms) | 예산(ms) |\n| --- | --- | --- | --- | --- | --- | --- |\n'
		cat "$measure_flow_work/rows"
	} >"$measure_flow_work/report"
	cat "$measure_flow_work/report"
	[ -z "$measure_flow_summary" ] || cat "$measure_flow_work/report" >>"$measure_flow_summary"

	[ "$measure_flow_failed" = false ]
)

measure_flow_main "$@"
