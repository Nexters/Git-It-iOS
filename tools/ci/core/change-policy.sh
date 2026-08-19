#!/bin/sh
# PR 변경 경로 하나를 CI 분류 token으로 변환하는 순수 정책입니다.

set -eu

ci_change_policy_main() (
	[ "$#" -eq 1 ] || {
		printf '오류[ci.change-policy.invalid-input]: 변경 경로 하나가 필요합니다\n조치: NUL 경계에서 복원한 경로를 한 개씩 전달하세요\n' >&2
		return 2
	}

	ci_change_file=$1
	ci_change_classified=false

	# 문서 경로는 다른 실행 분류보다 먼저 확정해 fast path를 유지합니다.
	case "$ci_change_file" in
	*.md | LICENSE | docs/* | */docs/* | specs/* | .specify/* | .agents/*)
		printf '%s\n' file docs
		return 0
		;;
	esac

	printf '%s\n' file non_docs

	# GitHub workflow와 프로젝트 셸은 각각 독립된 품질 검사를 활성화합니다.
	case "$ci_change_file" in
	.github/workflows/*)
		printf '%s\n' workflow
		ci_change_classified=true
		;;
	esac
	case "$ci_change_file" in
	tools/* | *.sh)
		printf '%s\n' scripts
		ci_change_classified=true
		;;
	esac

	# Tuist manifest 변경은 전체 앱·테스트 검증으로 보수적으로 승격합니다.
	case "$ci_change_file" in
	*/Project.swift | */Workspace.swift | */Tuist/* | .gitmodules)
		printf '%s\n' project_config
		ci_change_classified=true
		;;
	esac

	# Swift와 프로젝트 입력 리소스는 앱 빌드와 단위 테스트 대상입니다.
	case "$ci_change_file" in
	*.swift)
		printf '%s\n' swift
		ci_change_classified=true
		;;
	esac
	case "$ci_change_file" in
	*/Projects/*)
		printf '%s\n' source_input
		ci_change_classified=true
		;;
	esac

	# UI와 테스트 경로는 전용 job 조건도 함께 활성화합니다.
	case "$ci_change_file" in
	*/Projects/UI/*)
		printf '%s\n' ui
		ci_change_classified=true
		;;
	esac
	case "$ci_change_file" in
	*/Tests/* | */UITests/* | */*Tests/*)
		printf '%s\n' tests
		ci_change_classified=true
		;;
	esac

	# 새 비문서 형식을 놓치더라도 CI 검사를 생략하지 않습니다.
	if [ "$ci_change_classified" = false ]; then
		printf '%s\n' conservative
	fi
)

ci_change_policy_main "$@"
