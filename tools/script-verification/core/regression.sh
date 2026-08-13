# shellcheck disable=SC1091
# syntax, 정적 도구와 검증기 자체 회귀를 집계합니다.

verification_collect_targets() (
	verification_collect_output=$1
	: >"$verification_collect_output"
	. "$VERIFICATION_SUITE_ROOT/config/verification.conf"
	for verification_collect_relative in $VERIFICATION_SCRIPT_TARGETS; do
		verification_collect_target="$VERIFICATION_ROOT/$verification_collect_relative"
		[ -d "$verification_collect_target" ] || continue
		case "$verification_collect_relative" in
		"$VERIFICATION_GITHOOKS_ROOT") find "$verification_collect_target" -type f ! -name ".DS_Store" -print0 >>"$verification_collect_output" ;;
		*) find "$verification_collect_target" -type f -name '*.sh' -print0 >>"$verification_collect_output" ;;
		esac
	done
	case "$VERIFICATION_SUITE_ROOT/" in
	"$VERIFICATION_ROOT/$VERIFICATION_GITHOOKS_ROOT/"*) ;;
	*) find "$VERIFICATION_SUITE_ROOT" -type f -name '*.sh' -print0 >>"$verification_collect_output" ;;
	esac
)

verification_syntax_run() (
	[ -s "$VERIFICATION_TARGET_FILE" ] || return 0
	xargs -0 -n 1 /bin/sh -n <"$VERIFICATION_TARGET_FILE"
)

verification_static_run() (
	verification_static_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-static.XXXXXX") || return 2
	trap 'rm -rf "$verification_static_work"' EXIT
	VERIFICATION_TARGET_FILE="$verification_static_work/targets.nul"
	export VERIFICATION_TARGET_FILE
	verification_collect_targets "$VERIFICATION_TARGET_FILE" || return 2
	verification_static_failures=0
	verification_syntax_run || verification_static_failures=$((verification_static_failures + 1))
	verification_shellcheck_run || verification_static_failures=$((verification_static_failures + 1))
	verification_shfmt_run || verification_static_failures=$((verification_static_failures + 1))
	[ "$verification_static_failures" -eq 0 ] || {
		printf '오류[script-verification.static-failed]: 정적 검사 %s개 실패\n조치: 위 파일의 syntax, ShellCheck와 shfmt 위반을 수정하세요\n' "$verification_static_failures" >&2
		return 1
	}
)

verification_regression_run() (
	verification_regression_list=$(mktemp "${TMPDIR:-/tmp}/git-it-regression-list.XXXXXX") || return 2
	verification_regression_failed=$(mktemp "${TMPDIR:-/tmp}/git-it-regression-failed.XXXXXX") || return 2
	trap 'rm -f "$verification_regression_list" "$verification_regression_failed"' EXIT
	find "$VERIFICATION_SUITE_ROOT/tests" -type f -name 'test-*.sh' -print | LC_ALL=C sort >"$verification_regression_list"
	: >"$verification_regression_failed"
	while IFS= read -r verification_regression_test; do
		[ -n "$verification_regression_test" ] || continue
		if VERIFICATION_NESTED=1 /bin/sh "$verification_regression_test"; then
			printf '회귀 통과: %s\n' "${verification_regression_test#"$VERIFICATION_SUITE_ROOT/"}"
		else
			printf '%s\n' "${verification_regression_test#"$VERIFICATION_SUITE_ROOT/"}" >>"$verification_regression_failed"
		fi
	done <"$verification_regression_list"
	[ ! -s "$verification_regression_failed" ] || {
		printf '오류[script-verification.regression-failed]: 다음 회귀가 실패했습니다\n' >&2
		sed 's/^/  /' "$verification_regression_failed" >&2
		printf '조치: 실패 테스트를 직접 실행해 안정 code와 원인을 확인하세요\n' >&2
		return 1
	}
)
