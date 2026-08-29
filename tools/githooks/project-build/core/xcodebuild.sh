#!/bin/sh
# Debug iOS Simulator Xcode action port입니다. source와 helper 실행을 모두 지원합니다.

project_xcodebuild_all() (
	project_xcodebuild_workspace=$1
	project_xcodebuild_derived_root=$2
	project_xcodebuild_destination=$3
	project_xcodebuild_operation=$4
	project_xcodebuild_action=$5
	project_xcodebuild_targets=$6
	project_xcodebuild_results=$7
	project_xcodebuild_helper=$8

	: >"$project_xcodebuild_results"
	# NUL 경계를 보존한 채 각 scheme을 helper의 마지막 argv로 전달합니다.
	xargs -0 -n 1 "$project_xcodebuild_helper" --run-one \
		"$project_xcodebuild_workspace" \
		"$project_xcodebuild_derived_root" \
		"$project_xcodebuild_destination" \
		"$project_xcodebuild_operation" \
		"$project_xcodebuild_action" \
		"$project_xcodebuild_results" <"$project_xcodebuild_targets"
)

project_xcodebuild_one() {
	project_xcodebuild_workspace=$1
	project_xcodebuild_derived_root=$2
	project_xcodebuild_destination=$3
	project_xcodebuild_operation=$4
	project_xcodebuild_action=$5
	project_xcodebuild_results=$6
	project_xcodebuild_scheme_file=$7
	project_xcodebuild_scheme=$(basename -- "$project_xcodebuild_scheme_file" .xcscheme)
	project_xcodebuild_arch=$(uname -m)
	project_xcodebuild_jobs=${GIT_IT_XCODE_JOBS:-1}

	case "$project_xcodebuild_scheme" in
	'' | *[!A-Za-z0-9._-]*)
		printf 'failed\t%s\n' "$project_xcodebuild_scheme" >>"$project_xcodebuild_results"
		return 1
		;;
	esac
	case "$project_xcodebuild_arch" in arm64 | x86_64) ;; *) return 2 ;; esac
	case "$project_xcodebuild_jobs" in
	'' | *[!0-9]*)
		printf '오류[project-build.invalid-jobs]: GIT_IT_XCODE_JOBS=%s\n조치: 1~32 사이의 정수를 지정하세요\n' \
			"$project_xcodebuild_jobs" >&2
		return 2
		;;
	esac
	[ "$project_xcodebuild_jobs" -ge 1 ] && [ "$project_xcodebuild_jobs" -le 32 ] || {
		printf '오류[project-build.invalid-jobs]: GIT_IT_XCODE_JOBS=%s\n조치: 1~32 사이의 정수를 지정하세요\n' \
			"$project_xcodebuild_jobs" >&2
		return 2
	}
	case "$project_xcodebuild_action" in build | build-for-testing | test-without-building | test) ;; *) return 2 ;; esac

	# 테스트 scheme만 별도 제품 디렉터리에 격리하고 compile과 test는 같은 빌드를 공유합니다.
	if grep -q '<TestableReference' "$project_xcodebuild_scheme_file"; then
		project_xcodebuild_derived="$project_xcodebuild_derived_root/TestSchemes/$project_xcodebuild_scheme"
	else
		project_xcodebuild_grep_exit=$?
		[ "$project_xcodebuild_grep_exit" -eq 1 ] || return 2
		project_xcodebuild_derived=$project_xcodebuild_derived_root
	fi
	printf '%s 시작: %s\n' "$project_xcodebuild_operation" "$project_xcodebuild_scheme"
	project_xcodebuild_started_at=$(date +%s) || return 2
	# 호출자가 결과 경로를 제공하면 test action마다 충돌 없는 xcresult를 남깁니다.
	set -- \
		-quiet \
		-workspace "$project_xcodebuild_workspace" \
		-scheme "$project_xcodebuild_scheme" \
		-configuration Debug \
		-destination "$project_xcodebuild_destination" \
		-derivedDataPath "$project_xcodebuild_derived" \
		-disableAutomaticPackageResolution \
		-jobs "$project_xcodebuild_jobs"
	project_xcodebuild_result_root=${GIT_IT_XCRESULTS_PATH:-}
	if [ -n "$project_xcodebuild_result_root" ]; then
		case "$project_xcodebuild_action" in
		test | test-without-building)
			mkdir -p "$project_xcodebuild_result_root" || return 2
			project_xcodebuild_result="$project_xcodebuild_result_root/$project_xcodebuild_scheme-$$.xcresult"
			set -- "$@" -resultBundlePath "$project_xcodebuild_result"
			printf '테스트 결과 경로: %s\n' "$project_xcodebuild_result"
			;;
		esac
	fi
	if xcodebuild "$@" \
		"$project_xcodebuild_action" \
		CODE_SIGNING_ALLOWED=NO \
		COMPILER_INDEX_STORE_ENABLE=NO \
		ONLY_ACTIVE_ARCH=YES \
		"ARCHS=$project_xcodebuild_arch"; then
		project_xcodebuild_finished_at=$(date +%s) || return 2
		project_xcodebuild_elapsed=$((project_xcodebuild_finished_at - project_xcodebuild_started_at))
		printf 'succeeded\t%s\n' "$project_xcodebuild_scheme" >>"$project_xcodebuild_results"
		printf '%s 완료: %s 경과=%ss\n' \
			"$project_xcodebuild_operation" "$project_xcodebuild_scheme" "$project_xcodebuild_elapsed"
	else
		project_xcodebuild_finished_at=$(date +%s) || return 2
		project_xcodebuild_elapsed=$((project_xcodebuild_finished_at - project_xcodebuild_started_at))
		printf 'failed\t%s\n' "$project_xcodebuild_scheme" >>"$project_xcodebuild_results"
		printf '오류[project-build.scheme-failed]: 작업=%s scheme=%s action=%s 경과=%ss 실패\n' \
			"$project_xcodebuild_operation" "$project_xcodebuild_scheme" \
			"$project_xcodebuild_action" "$project_xcodebuild_elapsed" >&2
		return 1
	fi
}

if [ "${1:-}" = --run-one ]; then
	shift
	project_xcodebuild_one "$@"
fi
