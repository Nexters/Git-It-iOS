#!/bin/sh
# 차단 CI job 결과를 종합해 최종 pass/fail을 결정합니다.

set -eu

gate_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=../core/gate-policy.sh
. "$gate_bin/../core/gate-policy.sh"

gate_evaluate_main() (
	if [ "$#" -eq 0 ]; then
		printf '오류[ci.gate-evaluate.invalid-input]: 최소 하나의 job 결과가 필요합니다\n조치: gate-evaluate.sh <result1> <result2> ... 형식으로 실행하세요\n' >&2
		return 2
	fi

	gate_failed_jobs=0
	gate_passed_jobs=0
	gate_skipped_jobs=0

	# 순수 정책 token을 집계해 GitHub 상태 문자열 처리를 한 곳에 둡니다.
	for gate_result in "$@"; do
		gate_token=$(ci_gate_result_policy "$gate_result") || return $?
		case "$gate_token" in
		passed) gate_passed_jobs=$((gate_passed_jobs + 1)) ;;
		skipped) gate_skipped_jobs=$((gate_skipped_jobs + 1)) ;;
		failed) gate_failed_jobs=$((gate_failed_jobs + 1)) ;;
		*)
			printf '오류[ci.gate-evaluate.unknown-result]: 알 수 없는 job 결과 %s\n조치: GitHub Actions의 job status(success, skipped, failure, cancelled)를 사용하세요\n' \
				"$gate_result" >&2
			return 2
			;;
		esac
	done

	# step summary와 종료 상태가 동일한 집계값을 사용합니다.
	if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
		{
			printf '## CI / gate 결과 평가\n\n'
			printf '| 상태 | 개수 |\n'
			printf '|------|------|\n'
			printf '| ✅ 성공 (Success) | %s |\n' "$gate_passed_jobs"
			printf '| ⏭️ 생략 (Skipped) | %s |\n' "$gate_skipped_jobs"
			printf '| ❌ 실패 (Failure/Cancelled) | %s |\n' "$gate_failed_jobs"
			printf '\n'
			if [ "$gate_failed_jobs" -gt 0 ]; then
				printf '결과: **실패** (차단 job 실패 존재)\n'
			else
				printf '결과: **성공** (모든 차단 job 통과 또는 생략)\n'
			fi
		} >>"$GITHUB_STEP_SUMMARY"
	fi

	if [ "$gate_failed_jobs" -gt 0 ]; then
		printf '평가 실패: %s개 job 실패\n' "$gate_failed_jobs"
		return 1
	fi

	printf '평가 통과\n'
)

gate_evaluate_main "$@"
