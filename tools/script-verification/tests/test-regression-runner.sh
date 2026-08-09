#!/bin/sh
# shellcheck disable=SC1091,SC2016
set -eu

if [ "${VERIFICATION_NESTED:-0}" = 1 ]; then
	printf 'PASS: regression runner nested guard\n'
	exit 0
fi

suite=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
. "$suite/core/regression.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/regression-runner-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
fixture="$work/suite"
mkdir -p "$fixture/tests"
printf '#!/bin/sh\nprintf one >> "$REGRESSION_LOG"\nexit 0\n' >"$fixture/tests/test-one.sh"
printf '#!/bin/sh\nprintf two >> "$REGRESSION_LOG"\nexit 1\n' >"$fixture/tests/test-two.sh"
printf '#!/bin/sh\nprintf three >> "$REGRESSION_LOG"\nexit 0\n' >"$fixture/tests/test-three.sh"
chmod +x "$fixture/tests/test-one.sh" "$fixture/tests/test-two.sh" "$fixture/tests/test-three.sh"
VERIFICATION_SUITE_ROOT=$fixture
REGRESSION_LOG="$work/calls"
export VERIFICATION_SUITE_ROOT REGRESSION_LOG
if verification_regression_run >"$work/out" 2>"$work/err"; then exit 1; fi
[ "$(cat "$REGRESSION_LOG")" = onethreetwo ]
rg -q 'script-verification.regression-failed' "$work/err"
rg -q 'test-two.sh' "$work/err"
printf 'PASS: regression runner\n'
