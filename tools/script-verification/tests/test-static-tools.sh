#!/bin/sh
# shellcheck disable=SC1091,SC2016
set -eu

suite=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
. "$suite/core/shellcheck.sh"
. "$suite/core/shfmt.sh"
. "$suite/core/regression.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/static-tools-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
fixture="$work/repository"
fixture_suite="$work/suite"
fixture_hooks_root='fixture-hooks'
mkdir -p "$fixture_suite/.build/bin" \
	"$fixture_suite/.build/artifacts" \
	"$fixture_suite/dependencies" \
	"$fixture_suite/config" "$fixture_suite/tests" "$fixture/$fixture_hooks_root/example" "$fixture/$fixture_hooks_root" \
	"$fixture/tools/repository-paths/bin"
printf '#!/bin/sh\nprintf ok\n' >"$fixture/$fixture_hooks_root/example/run.sh"
printf '#!/bin/sh\nprintf paths\n' >"$fixture/tools/repository-paths/bin/repository-paths.sh"
chmod +x "$fixture/$fixture_hooks_root/example/run.sh"
printf '%s\n' '#!/bin/sh' \
	'printf "%s\n" "$*" >> "$STATIC_LOG"' \
	'case "$1" in --version) printf "ShellCheck - shell script analysis tool\nversion: 0.11.0\n";; esac' \
	'exit "${STATIC_EXIT:-0}"' >"$fixture_suite/.build/bin/shellcheck"
printf '%s\n' '#!/bin/sh' \
	'printf "%s\n" "$*" >> "$STATIC_LOG"' \
	'case "$1" in --version) printf "v3.13.1\n";; esac' \
	'exit "${STATIC_EXIT:-0}"' >"$fixture_suite/.build/bin/shfmt"
chmod +x "$fixture_suite/.build/bin/shellcheck" "$fixture_suite/.build/bin/shfmt"
cp "$fixture_suite/.build/bin/shellcheck" "$fixture_suite/.build/artifacts/shellcheck"
cp "$fixture_suite/.build/bin/shfmt" "$fixture_suite/.build/artifacts/shfmt"
shellcheck_sha=$(shasum -a 256 "$fixture_suite/.build/artifacts/shellcheck" | awk '{print $1}')
shfmt_sha=$(shasum -a 256 "$fixture_suite/.build/artifacts/shfmt" | awk '{print $1}')
printf '%s\n' \
	"shellcheck|0.11.0|darwin-arm64|shellcheck|fixture://shellcheck|$shellcheck_sha|binary|shellcheck" \
	"shfmt|3.13.1|darwin-arm64|shfmt|fixture://shfmt|$shfmt_sha|binary|shfmt" \
	>"$fixture_suite/dependencies/tools.lock"
cp "$suite/config/verification.conf" "$fixture_suite/config/verification.conf"

VERIFICATION_ROOT=$fixture
VERIFICATION_SUITE_ROOT=$fixture_suite
VERIFICATION_GITHOOKS_ROOT=$fixture_hooks_root
VERIFICATION_PLATFORM=darwin-arm64
STATIC_LOG="$work/static.log"
export VERIFICATION_ROOT VERIFICATION_SUITE_ROOT VERIFICATION_GITHOOKS_ROOT VERIFICATION_PLATFORM STATIC_LOG
: >"$STATIC_LOG"
before=$(find "$fixture_suite/.build" -type f -exec cksum {} \; | sort)
verification_dependency_check
verification_static_run
after=$(find "$fixture_suite/.build" -type f -exec cksum {} \; | sort)
[ "$before" = "$after" ]
rg -q -- '--shell=sh' "$STATIC_LOG"
rg -q -- '^-d' "$STATIC_LOG"
rg -Fq "$fixture/tools/repository-paths/bin/repository-paths.sh" "$STATIC_LOG"

rm "$fixture_suite/.build/bin/shfmt"
if verification_dependency_check >"$work/out" 2>"$work/err"; then exit 1; fi
rg -q 'script-verification.dependency-invalid' "$work/err"
[ ! -e "$fixture_suite/.build/bin/shfmt" ]
printf 'PASS: static tools\n'
