# shellcheck disable=SC1091
# 준비된 ShellCheck artifact의 lock 일치와 고정 옵션 실행을 담당합니다.

verification_dependency_check() (
	verification_dependency_platform=${VERIFICATION_PLATFORM:-$(verification_platform_detect)} || return 2
	verification_dependency_lock="$VERIFICATION_SUITE_ROOT/dependencies/tools.lock"
	verification_dependency_build="$VERIFICATION_SUITE_ROOT/.build"
	verification_dependency_failures=0

	for verification_dependency_name in shellcheck shfmt; do
		verification_dependency_line=$(awk -F '|' -v tool="$verification_dependency_name" -v platform="$verification_dependency_platform" \
			'$1 == tool && $3 == platform { print; exit }' "$verification_dependency_lock")
		[ -n "$verification_dependency_line" ] || {
			verification_dependency_failures=$((verification_dependency_failures + 1))
			continue
		}
		# lock record 전체 형식을 함께 검증합니다.
		# shellcheck disable=SC2034
		IFS='|' read -r verification_name verification_version verification_platform \
			verification_artifact verification_url verification_sha verification_archive verification_binary <<EOF
$verification_dependency_line
EOF
		verification_dependency_executable="$verification_dependency_build/bin/$verification_name"
		verification_dependency_artifact="$verification_dependency_build/artifacts/$verification_artifact"
		if [ ! -x "$verification_dependency_executable" ] || [ ! -f "$verification_dependency_artifact" ]; then
			printf '오류[script-verification.dependency-invalid]: %s %s 준비 artifact 누락\n조치: tools/script-verification/bin/prepare-tools.sh를 실행하세요\n' "$verification_name" "$verification_version" >&2
			verification_dependency_failures=$((verification_dependency_failures + 1))
			continue
		fi
		verification_dependency_actual_sha=$(shasum -a 256 "$verification_dependency_artifact" | awk '{print $1}') || return 2
		if [ "$verification_dependency_actual_sha" != "$verification_sha" ]; then
			printf '오류[script-verification.dependency-invalid]: %s checksum 불일치\n조치: .build를 제거하고 prepare-tools.sh를 다시 실행하세요\n' "$verification_name" >&2
			verification_dependency_failures=$((verification_dependency_failures + 1))
			continue
		fi
		case "$verification_name" in
		shellcheck) verification_dependency_actual_version=$("$verification_dependency_executable" --version | sed -n 's/^version: //p') ;;
		shfmt)
			verification_dependency_actual_version=$("$verification_dependency_executable" --version)
			verification_dependency_actual_version=${verification_dependency_actual_version#v}
			;;
		esac
		if [ "$verification_dependency_actual_version" != "$verification_version" ]; then
			printf '오류[script-verification.dependency-invalid]: %s version 기대=%s 실제=%s\n조치: prepare-tools.sh를 다시 실행하세요\n' \
				"$verification_name" "$verification_version" "$verification_dependency_actual_version" >&2
			verification_dependency_failures=$((verification_dependency_failures + 1))
		fi
	done
	[ "$verification_dependency_failures" -eq 0 ]
)

verification_shellcheck_run() (
	. "$VERIFICATION_SUITE_ROOT/config/verification.conf"
	verification_shellcheck="$VERIFICATION_SUITE_ROOT/.build/bin/shellcheck"
	[ -x "$verification_shellcheck" ] || return 1
	verification_shellcheck_targets=${VERIFICATION_TARGET_FILE:?}
	[ -s "$verification_shellcheck_targets" ] || return 0
	# 저장소 고정 옵션 문자열을 의도적으로 argv로 분리합니다.
	# shellcheck disable=SC2086
	set -- $SHELLCHECK_OPTIONS
	xargs -0 "$verification_shellcheck" "$@" <"$verification_shellcheck_targets"
)
