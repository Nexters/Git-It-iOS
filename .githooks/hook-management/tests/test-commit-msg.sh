#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd -P)
work=$(mktemp -d "${TMPDIR:-/tmp}/commit-message-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/repository"
mkdir -p "$repository/.githooks"
cp "$root/.githooks/commit-msg" "$repository/.githooks/commit-msg"
git -C "$repository" init -q

printf '[Feat] 스크립트 구조 개선\n\nbody\n' >"$work/message"
"$repository/.githooks/commit-msg" "$work/message"

printf '[Docs] "README" 설명 추가\n' >"$work/message"
"$repository/.githooks/commit-msg" "$work/message"

printf '[Unknown] 잘못된 태그\n' >"$work/message"
if "$repository/.githooks/commit-msg" "$work/message" >"$work/out" 2>"$work/err"; then
	exit 1
else
	result=$?
fi
[ "$result" -eq 1 ]
rg -q 'commit-convention.message-invalid' "$work/err"
rg -q '.github/COMMIT_CONVENTION.md' "$work/err"

printf 'Feat: 잘못된 형식\n' >"$work/message"
if "$repository/.githooks/commit-msg" "$work/message" >/dev/null 2>&1; then
	exit 1
else
	result=$?
fi
[ "$result" -eq 1 ]

if "$repository/.githooks/commit-msg" "$work/missing" >/dev/null 2>&1; then
	exit 1
else
	result=$?
fi
[ "$result" -eq 2 ]

[ ! -e "$repository/scripts" ]
printf 'PASS: standalone commit-msg\n'
