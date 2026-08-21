#!/bin/sh
# shellcheck disable=SC2016
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../../.." && pwd -P)
source_paths="$root/tools/repository-paths/bin/repository-paths.sh"
config_relative=$("$source_paths" GIT_IT_PATHS_FILE)
hooks_relative=$("$source_paths" GIT_IT_HOOKS_ROOT)
swift_runner_relative=$("$source_paths" GIT_IT_SWIFT_FORMAT_RUNNER)
project_runner_relative=$("$source_paths" GIT_IT_PROJECT_BUILD_RUNNER)
script_tests_runner_relative=$("$source_paths" GIT_IT_SCRIPT_TEST_RUNNER)
work=$(mktemp -d "${TMPDIR:-/tmp}/pre-commit-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/repository"
mkdir -p "$repository/$hooks_relative/pre-commit.d"
cp "$root/$hooks_relative/pre-commit" "$repository/$hooks_relative/pre-commit"
git -C "$repository" init -q

stage_dir="$repository/$hooks_relative/pre-commit.d"
enabled="$stage_dir/enabled"
PRE_COMMIT_LOG="$work/calls"
export PRE_COMMIT_LOG

for step in script-tests swift-format build compile; do
	script="$stage_dir/$step.sh"
	printf '%s\n' '#!/bin/sh' \
		'[ -z "${GIT_DIR:-}" ] || exit 1' \
		'printf "%s\n" "$(basename "$0" .sh)" >> "$PRE_COMMIT_LOG"' \
		'exit "${PRE_COMMIT_STUB_EXIT:-0}"' >"$script"
	chmod +x "$script"
done

# 1. enabled가 없으면 스크립트가 있어도 실행하지 않는다.
: >"$PRE_COMMIT_LOG"
"$repository/$hooks_relative/pre-commit" >"$work/out" 2>"$work/err"
[ ! -s "$PRE_COMMIT_LOG" ] || {
	printf 'FAIL: enabled 부재인데 단계 실행\n' >&2
	exit 1
}

# 2. 활성화한 단계를 고정 순서로 실행한다. enabled의 줄 순서는 따르지 않는다.
: >"$PRE_COMMIT_LOG"
printf '%s\n' '# 주석' '' 'compile' 'build' 'swift-format' 'script-tests' >"$enabled"
GIT_DIR="$work/outside-git-dir"
export GIT_DIR
"$repository/$hooks_relative/pre-commit" >"$work/out" 2>"$work/err"
expected=$(printf 'script-tests\nswift-format\nbuild\ncompile')
[ "$(cat "$PRE_COMMIT_LOG")" = "$expected" ] || {
	printf 'FAIL: pre-commit 실행 순서\n' >&2
	exit 1
}

# 3. 활성화하지 않은 단계는 스크립트가 있어도 실행하지 않는다.
: >"$PRE_COMMIT_LOG"
printf '%s\n' 'script-tests' 'swift-format' 'compile' >"$enabled"
"$repository/$hooks_relative/pre-commit" >"$work/out" 2>"$work/err"
expected=$(printf 'script-tests\nswift-format\ncompile')
[ "$(cat "$PRE_COMMIT_LOG")" = "$expected" ] || {
	printf 'FAIL: 비활성 단계 실행\n' >&2
	exit 1
}

# 4. 한 단계가 실패하면 즉시 중단하고 종료 코드를 그대로 전파하며 리포트를 작성한다.
: >"$PRE_COMMIT_LOG"
printf '%s\n' 'script-tests' 'swift-format' 'build' 'compile' >"$enabled"
printf '%s\n' '#!/bin/sh' \
	'printf "compile\n" >> "$PRE_COMMIT_LOG"' \
	'exit 17' >"$stage_dir/compile.sh"
if "$repository/$hooks_relative/pre-commit" >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 실패 단계 이후에도 pre-commit 성공\n' >&2
	exit 1
else
	result=$?
fi
[ "$result" -eq 17 ]
expected=$(printf 'script-tests\nswift-format\nbuild\ncompile')
[ "$(cat "$PRE_COMMIT_LOG")" = "$expected" ]
rg -q 'pre-commit.step-failed' "$work/err"
rg -Fq 'pre-commit 리포트' "$work/err"
rg -Fq '| compile | failure:17 |' "$work/err"

# 5. 알 수 없는 단계 이름은 조용히 무시하지 않고 실패한다.
printf '%s\n' 'swift-formt' >"$enabled"
if "$repository/$hooks_relative/pre-commit" >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 알 수 없는 단계 이름을 통과\n' >&2
	exit 1
fi
rg -q 'common.invalid-input' "$work/err"

# 6. 활성화됐는데 스크립트가 없으면 건너뛰지 않고 실패한다.
printf '%s\n' 'build' >"$enabled"
rm "$stage_dir/build.sh"
if "$repository/$hooks_relative/pre-commit" >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 활성 단계의 스크립트 부재를 통과\n' >&2
	exit 1
fi
rg -q 'common.invalid-input' "$work/err"

# 7. 복사된 단계 스크립트는 원본 저장소가 아닌 자신의 저장소에서 공개 명령을 실행한다.
stage_repository="$work/stage-repository"
mkdir -p "$stage_repository/$hooks_relative/pre-commit.d" \
	"$(dirname -- "$stage_repository/${source_paths#"$root/"}")" \
	"$(dirname -- "$stage_repository/$swift_runner_relative")" \
	"$(dirname -- "$stage_repository/$project_runner_relative")" \
	"$(dirname -- "$stage_repository/$script_tests_runner_relative")"
stage_repository=$(CDPATH='' cd -- "$stage_repository" && pwd -P)
cp "$source_paths" "$stage_repository/${source_paths#"$root/"}"
cp "$root/$config_relative" "$stage_repository/$config_relative"
for step in script-tests swift-format build compile; do
	cp "$root/$hooks_relative/pre-commit.d/$step.sh" "$stage_repository/$hooks_relative/pre-commit.d/$step.sh"
done
printf '%s\n' '#!/bin/sh' \
	'printf "swift-format:%s:%s\\n" "$PWD" "$1" >> "$PRE_COMMIT_LOG"' >"$stage_repository/$swift_runner_relative"
printf '%s\n' '#!/bin/sh' \
	'printf "project-build:%s:%s\\n" "$PWD" "$1" >> "$PRE_COMMIT_LOG"' >"$stage_repository/$project_runner_relative"
printf '%s\n' '#!/bin/sh' \
	'printf "script-tests:%s\\n" "$PWD" >> "$PRE_COMMIT_LOG"' >"$stage_repository/$script_tests_runner_relative"
chmod +x "$stage_repository/$swift_runner_relative" \
	"$stage_repository/$project_runner_relative" \
	"$stage_repository/$script_tests_runner_relative"
: >"$PRE_COMMIT_LOG"
(
	cd /
	"$stage_repository/$hooks_relative/pre-commit.d/script-tests.sh"
	"$stage_repository/$hooks_relative/pre-commit.d/swift-format.sh"
	"$stage_repository/$hooks_relative/pre-commit.d/build.sh"
	"$stage_repository/$hooks_relative/pre-commit.d/compile.sh"
)
expected=$(printf 'script-tests:%s\nswift-format:%s:staged\nproject-build:%s:build\nproject-build:%s:compile' \
	"$stage_repository" "$stage_repository" "$stage_repository" "$stage_repository")
[ "$(cat "$PRE_COMMIT_LOG")" = "$expected" ] || {
	printf 'FAIL: 단계 스크립트가 자신의 저장소에서 실행되지 않음\n' >&2
	exit 1
}

printf 'PASS: pre-commit hook\n'
