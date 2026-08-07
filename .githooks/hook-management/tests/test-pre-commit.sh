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

stage_dir="$repository/.githooks/pre-commit.d"
enabled="$stage_dir/enabled"
PRE_COMMIT_LOG="$work/calls"
export PRE_COMMIT_LOG

for step in swift-format build compile test; do
	script="$stage_dir/$step.sh"
	printf '%s\n' '#!/bin/sh' \
		'printf "%s\n" "$(basename "$0" .sh)" >> "$PRE_COMMIT_LOG"' \
		'exit "${PRE_COMMIT_STUB_EXIT:-0}"' >"$script"
	chmod +x "$script"
done

# 1. enabled가 없으면 스크립트가 있어도 실행하지 않는다.
: >"$PRE_COMMIT_LOG"
"$repository/.githooks/pre-commit" >"$work/out" 2>"$work/err"
[ ! -s "$PRE_COMMIT_LOG" ] || {
	printf 'FAIL: enabled 부재인데 단계 실행\n' >&2
	exit 1
}

# 2. 활성화한 단계를 고정 순서로 실행한다. enabled의 줄 순서는 따르지 않는다.
: >"$PRE_COMMIT_LOG"
printf '%s\n' '# 주석' '' 'test' 'compile' 'build' 'swift-format' >"$enabled"
"$repository/.githooks/pre-commit" >"$work/out" 2>"$work/err"
expected=$(printf 'swift-format\nbuild\ncompile\ntest')
[ "$(cat "$PRE_COMMIT_LOG")" = "$expected" ] || {
	printf 'FAIL: pre-commit 실행 순서\n' >&2
	exit 1
}

# 3. 활성화하지 않은 단계는 스크립트가 있어도 실행하지 않는다.
: >"$PRE_COMMIT_LOG"
printf '%s\n' 'swift-format' 'compile' >"$enabled"
"$repository/.githooks/pre-commit" >"$work/out" 2>"$work/err"
expected=$(printf 'swift-format\ncompile')
[ "$(cat "$PRE_COMMIT_LOG")" = "$expected" ] || {
	printf 'FAIL: 비활성 단계 실행\n' >&2
	exit 1
}

# 4. 한 단계가 실패하면 즉시 중단하고 종료 코드를 그대로 전파한다.
: >"$PRE_COMMIT_LOG"
printf '%s\n' 'swift-format' 'build' 'compile' 'test' >"$enabled"
printf '%s\n' '#!/bin/sh' \
	'printf "compile\n" >> "$PRE_COMMIT_LOG"' \
	'exit 17' >"$stage_dir/compile.sh"
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

# 5. 알 수 없는 단계 이름은 조용히 무시하지 않고 실패한다.
printf '%s\n' 'swift-formt' >"$enabled"
if "$repository/.githooks/pre-commit" >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 알 수 없는 단계 이름을 통과\n' >&2
	exit 1
fi
rg -q 'common.invalid-input' "$work/err"

# 6. 활성화됐는데 스크립트가 없으면 건너뛰지 않고 실패한다.
printf '%s\n' 'build' >"$enabled"
rm "$stage_dir/build.sh"
if "$repository/.githooks/pre-commit" >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 활성 단계의 스크립트 부재를 통과\n' >&2
	exit 1
fi
rg -q 'common.invalid-input' "$work/err"

printf 'PASS: pre-commit hook\n'
