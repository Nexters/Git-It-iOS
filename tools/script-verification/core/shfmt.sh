# shellcheck disable=SC1091
# 준비된 shfmt artifact로 고정 POSIX diff 검사를 수행합니다.

verification_shfmt_run() (
	. "$VERIFICATION_SUITE_ROOT/config/verification.conf"
	verification_shfmt="$VERIFICATION_SUITE_ROOT/.build/bin/shfmt"
	[ -x "$verification_shfmt" ] || return 1
	verification_shfmt_targets=${VERIFICATION_TARGET_FILE:?}
	[ -s "$verification_shfmt_targets" ] || return 0
	# 저장소 고정 옵션 문자열을 의도적으로 argv로 분리합니다.
	# shellcheck disable=SC2086
	set -- $SHFMT_OPTIONS
	xargs -0 "$verification_shfmt" "$@" <"$verification_shfmt_targets"
)
