#!/bin/sh
# shellcheck disable=SC1091
set -eu

suite=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
root=$(git -C "$suite" rev-parse --show-toplevel)
. "$suite/core/tool-dependency.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/prepare-tools-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
fixture="$work/suite"
mkdir -p "$fixture/dependencies" "$work/artifacts"

printf '%s\n' '#!/bin/sh' 'printf "ShellCheck - shell script analysis tool\nversion: 0.11.0\n"' >"$work/artifacts/shellcheck"
printf '%s\n' '#!/bin/sh' 'printf "v3.13.1\n"' >"$work/artifacts/shfmt"
chmod +x "$work/artifacts/shellcheck" "$work/artifacts/shfmt"
shellcheck_sha=$(shasum -a 256 "$work/artifacts/shellcheck" | awk '{print $1}')
shfmt_sha=$(shasum -a 256 "$work/artifacts/shfmt" | awk '{print $1}')
printf '%s\n' \
	"shellcheck|0.11.0|darwin-arm64|shellcheck|fixture://shellcheck|$shellcheck_sha|binary|shellcheck" \
	"shfmt|3.13.1|darwin-arm64|shfmt|fixture://shfmt|$shfmt_sha|binary|shfmt" \
	>"$fixture/dependencies/tools.lock"

VERIFICATION_SUITE_ROOT=$fixture
VERIFICATION_WORK="$work/prepare"
VERIFICATION_PLATFORM=darwin-arm64
VERIFICATION_FIXTURE_ARTIFACTS="$work/artifacts"
export VERIFICATION_SUITE_ROOT VERIFICATION_WORK VERIFICATION_PLATFORM VERIFICATION_FIXTURE_ARTIFACTS
mkdir -p "$VERIFICATION_WORK"
verification_lock_read
verification_artifacts_fetch
verification_artifacts_check
verification_artifacts_place
[ "$("$fixture/.build/bin/shellcheck" --version | sed -n 's/^version: //p')" = 0.11.0 ]
[ "$("$fixture/.build/bin/shfmt" --version)" = v3.13.1 ]
[ -f "$fixture/.build/artifacts/shellcheck" ]

rm -f "$work/artifacts/shfmt"
VERIFICATION_WORK="$work/incomplete"
export VERIFICATION_WORK
mkdir -p "$VERIFICATION_WORK"
verification_lock_read
if verification_artifacts_fetch 2>/dev/null; then
	printf 'FAIL: 불완전 artifact 준비 성공\n' >&2
	exit 1
fi
[ -x "$fixture/.build/bin/shfmt" ]
verification_suite_relative=${suite#"$root/"}
git -C "$root" check-ignore -q "$verification_suite_relative/.build/example"
printf 'PASS: prepare tools\n'
