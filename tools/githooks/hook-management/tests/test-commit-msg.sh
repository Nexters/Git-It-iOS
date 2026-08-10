#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../../../.." && pwd -P)
paths="$root/tools/repository-paths/bin/repository-paths.sh"
hooks_root=$("$paths" GIT_IT_HOOKS_ROOT)
work=$(mktemp -d "${TMPDIR:-/tmp}/commit-message-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/repository"
mkdir -p "$repository/$hooks_root"
cp "$root/$hooks_root/commit-msg" "$repository/$hooks_root/commit-msg"
git -C "$repository" init -q

printf '[Feat] 스크립트 구조 개선\n\nbody\n' >"$work/message"
"$repository/$hooks_root/commit-msg" "$work/message"

printf '[Docs] "README" 설명 추가\n' >"$work/message"
"$repository/$hooks_root/commit-msg" "$work/message"

printf '[Unknown] 잘못된 태그\n' >"$work/message"
if "$repository/$hooks_root/commit-msg" "$work/message" >"$work/out" 2>"$work/err"; then
	exit 1
else
	result=$?
fi
[ "$result" -eq 1 ]
rg -q 'commit-convention.message-invalid' "$work/err"
rg -q '.github/COMMIT_CONVENTION.md' "$work/err"

printf 'Feat: 잘못된 형식\n' >"$work/message"
if "$repository/$hooks_root/commit-msg" "$work/message" >/dev/null 2>&1; then
	exit 1
else
	result=$?
fi
[ "$result" -eq 1 ]

if "$repository/$hooks_root/commit-msg" "$work/missing" >/dev/null 2>&1; then
	exit 1
else
	result=$?
fi
[ "$result" -eq 2 ]

[ ! -e "$repository/scripts" ]
printf 'PASS: standalone commit-msg\n'
