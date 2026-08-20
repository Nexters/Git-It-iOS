#!/bin/sh
# shellcheck disable=SC2016
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
paths="$root/tools/repository-paths/bin/repository-paths.sh"
projects_relative=$("$paths" GIT_IT_PROJECTS_ROOT)
work=$(mktemp -d "${TMPDIR:-/tmp}/ci-lint-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/repository"
mkdir -p "$repository/tools/ci/bin" "$repository/tools/repository-paths/bin" "$repository/tools/swift"
cp "$module/bin/lint-changed-swift.sh" "$repository/tools/ci/bin/"
cp "$root/tools/repository-paths/bin/repository-paths.sh" "$repository/tools/repository-paths/bin/"
cp "$root/tools/repository-paths/repository-paths.json" "$repository/tools/repository-paths/"
git -C "$repository" init -q
git -C "$repository" config user.name ci
git -C "$repository" config user.email ci@example.com
printf 'base\n' >"$repository/README.md"
git -C "$repository" add -- .
git -C "$repository" commit -qm base
base=$(git -C "$repository" rev-parse HEAD)
newline=$(printf '화면\n상태.swift')
mkdir -p "$repository/$projects_relative/App"
printf 'struct App {}\n' >"$repository/$projects_relative/App/$newline"
git -C "$repository" add -- .
git -C "$repository" commit -qm head
head=$(git -C "$repository" rev-parse HEAD)
printf '%s\n' '#!/bin/sh' 'shift' 'printf "%s\n" "$@" >"$LINT_LOG"' >"$repository/tools/swift/lint.sh"
chmod +x "$repository/tools/swift/lint.sh" "$repository/tools/ci/bin/lint-changed-swift.sh"
LINT_LOG="$work/log" GIT_IT_SWIFT_FORMAT_RUNNER="$repository/tools/swift/lint.sh" \
	"$repository/tools/ci/bin/lint-changed-swift.sh" "$base" "$head"
[ "$(cat "$work/log")" = "$projects_relative/App/$newline" ]
printf 'PASS: CI changed Swift lint\n'
