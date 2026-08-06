#!/bin/sh
# shellcheck disable=SC2016
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd -P)
work=$(mktemp -d "${TMPDIR:-/tmp}/pre-commit-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/repository"
mkdir -p "$repository/.githooks/pre-commit.d"
cp "$root/.githooks/pre-commit" "$repository/.githooks/pre-commit"
git -C "$repository" init -q

for step in swift-format build compile test; do
	script="$repository/.githooks/pre-commit.d/$step.sh"
	printf '%s\n' '#!/bin/sh' \
		'printf "%s\n" "$(basename "$0" .sh)" >> "$PRE_COMMIT_LOG"' \
		'exit "${PRE_COMMIT_STUB_EXIT:-0}"' >"$script"
	chmod +x "$script"
done

PRE_COMMIT_LOG="$work/calls"
export PRE_COMMIT_LOG
"$repository/.githooks/pre-commit" >"$work/out" 2>"$work/err"
expected=$(printf 'swift-format\nbuild\ncompile\ntest')
[ "$(cat "$PRE_COMMIT_LOG")" = "$expected" ] || {
	printf 'FAIL: pre-commit 실행 순서\n' >&2
	exit 1
}

: >"$PRE_COMMIT_LOG"
printf '%s\n' '#!/bin/sh' \
	'printf "compile\n" >> "$PRE_COMMIT_LOG"' \
	'exit 17' >"$repository/.githooks/pre-commit.d/compile.sh"
if "$repository/.githooks/pre-commit" >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 실패 단계 이후에도 pre-commit 성공\n' >&2
	exit 1
else
	result=$?
fi
[ "$result" -eq 17 ]
expected=$(printf 'swift-format\nbuild\ncompile')
[ "$(cat "$PRE_COMMIT_LOG")" = "$expected" ]
rg -q 'pre-commit.step-failed' "$work/err"
if rg -q '^test$' "$PRE_COMMIT_LOG"; then
	printf 'FAIL: 실패 이후 단계 실행\n' >&2
	exit 1
fi
printf 'PASS: pre-commit hook\n'
