#!/bin/sh
# shellcheck disable=SC2016
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../../.." && pwd -P)
work=$(mktemp -d "${TMPDIR:-/tmp}/project-build-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/repository"
newline_project=$(printf 'Line\nBreak')
source_paths="$root/tools/repository-paths/bin/repository-paths.sh"
hooks_relative=$("$source_paths" GIT_IT_HOOKS_ROOT)
projects_relative=$("$source_paths" GIT_IT_PROJECTS_ROOT)
workspace_relative=$("$source_paths" GIT_IT_WORKSPACE_PATH)
derived_relative=$("$source_paths" GIT_IT_DERIVED_DATA_PATH)
config_relative=$("$source_paths" GIT_IT_PATHS_FILE)
project_runner_relative=$("$source_paths" GIT_IT_PROJECT_BUILD_RUNNER)
projects="$repository/$projects_relative"
workspace="$repository/$workspace_relative"
mkdir -p "$repository/$hooks_relative/pre-commit.d" "$work/bin"
cp -R "$root/$hooks_relative/project-build" "$repository/$hooks_relative/project-build"
mkdir -p "$repository/tools/repository-paths/bin"
cp "$source_paths" "$repository/tools/repository-paths/bin/repository-paths.sh"
cp "$root/$config_relative" "$repository/$config_relative"
cp "$root/$hooks_relative/pre-commit.d/build.sh" \
	"$root/$hooks_relative/pre-commit.d/compile.sh" \
	"$root/$hooks_relative/pre-commit.d/test.sh" \
	"$repository/$hooks_relative/pre-commit.d/"
git -C "$repository" init -q
mkdir -p "$workspace" \
	"$projects/App/xcshareddata/xcschemes" \
	"$projects/Tests/xcshareddata/xcschemes" \
	"$projects/Fail/xcshareddata/xcschemes" \
	"$projects/$newline_project/xcshareddata/xcschemes"
printf '<Scheme><Testables></Testables></Scheme>\n' \
	>"$projects/App/xcshareddata/xcschemes/App.xcscheme"
printf '<Scheme><Testables><TestableReference/></Testables></Scheme>\n' \
	>"$projects/Tests/xcshareddata/xcschemes/Tests.xcscheme"
printf '<Scheme><Testables></Testables></Scheme>\n' \
	>"$projects/Fail/xcshareddata/xcschemes/Fail.xcscheme"
printf '<Scheme><Testables></Testables></Scheme>\n' \
	>"$projects/$newline_project/xcshareddata/xcschemes/Newline.xcscheme"
printf '%s\n' '#!/bin/sh' \
	'scheme=' \
	'jobs=' \
	'action=' \
	'derived_data=' \
	'index_store=false' \
	'for argument do' \
	'  case "$argument" in' \
	'    -sdk) exit 90 ;;' \
	'    build | build-for-testing | test-without-building) action=$argument ;;' \
	'    COMPILER_INDEX_STORE_ENABLE=NO) index_store=true ;;' \
	'  esac' \
	'done' \
	'while [ "$#" -gt 0 ]; do' \
	'  if [ "$1" = -jobs ]; then jobs=$2; shift 2; continue; fi' \
	'  if [ "$1" = -derivedDataPath ]; then derived_data=$2; shift 2; continue; fi' \
	'  if [ "$1" = -scheme ]; then scheme=$2; shift 2; else shift; fi' \
	'done' \
	'[ "$jobs" = 1 ] || exit 91' \
	'[ "$index_store" = true ] || exit 92' \
	'case "$scheme" in Tests) expected_derived="$EXPECTED_DERIVED_ROOT/TestSchemes/$scheme" ;; *) expected_derived=$EXPECTED_DERIVED_ROOT ;; esac' \
	'[ "$derived_data" = "$expected_derived" ] || exit 93' \
	'printf "%s\t%s\n" "$action" "$scheme" >> "$PROJECT_ACTION_LOG"' \
	'[ "$scheme" != Fail ]' >"$work/bin/xcodebuild"
chmod +x "$work/bin/xcodebuild"

PROJECT_ACTION_LOG="$work/action.log" PATH="$work/bin:$PATH"
EXPECTED_DERIVED_ROOT="$(git -C "$repository" rev-parse --show-toplevel)/$derived_relative"
GIT_IT_TEST_DESTINATION='platform=iOS Simulator,name=Test Device'
export PROJECT_ACTION_LOG PATH EXPECTED_DERIVED_ROOT GIT_IT_TEST_DESTINATION

run_stage() (
	stage=$1
	shift
	# Git 훅과 같은 조건이 되도록 fixture 저장소 루트에서 실행합니다.
	cd "$repository"
	"$repository/$hooks_relative/pre-commit.d/$stage.sh" "$@"
)
run_project() (
	# 공개 명령의 입력 계약도 fixture 저장소 안에서 직접 검증합니다.
	cd "$repository"
	"$repository/$project_runner_relative" "$@"
)

if run_stage build >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 일부 scheme 실패를 성공으로 반환\n' >&2
	exit 1
fi
[ -f "$PROJECT_ACTION_LOG" ] || {
	cat "$work/out" "$work/err" >&2
	printf 'FAIL: xcodebuild가 실행되지 않음\n' >&2
	exit 1
}
[ "$(wc -l <"$PROJECT_ACTION_LOG" | tr -d ' ')" -eq 4 ] || {
	printf 'FAIL: 모든 build scheme을 시도하지 않음\n' >&2
	exit 1
}
rg -q '^build[[:space:]]+App$' "$PROJECT_ACTION_LOG"
rg -q '^build[[:space:]]+Tests$' "$PROJECT_ACTION_LOG"
rg -q '^build[[:space:]]+Fail$' "$PROJECT_ACTION_LOG"
rg -q '^build[[:space:]]+Newline$' "$PROJECT_ACTION_LOG"
rg -q '작업=build 시도=4 성공=3 실패=1' "$work/out"
rg -q 'project-build.scheme-failed' "$work/err"

rm "$projects/Fail/xcshareddata/xcschemes/Fail.xcscheme"
: >"$PROJECT_ACTION_LOG"
run_stage compile >"$work/out" 2>"$work/err"
[ "$(cat "$PROJECT_ACTION_LOG")" = "$(printf 'build-for-testing\tTests')" ]
rg -q '작업=compile 시도=1 성공=1 실패=0' "$work/out"

: >"$PROJECT_ACTION_LOG"
run_stage test >"$work/out" 2>"$work/err"
[ "$(cat "$PROJECT_ACTION_LOG")" = "$(printf 'test-without-building\tTests')" ]
rg -q '작업=test 시도=1 성공=1 실패=0' "$work/out"

rm "$projects/Tests/xcshareddata/xcschemes/Tests.xcscheme"
: >"$PROJECT_ACTION_LOG"
run_stage compile >"$work/out" 2>"$work/err"
[ ! -s "$PROJECT_ACTION_LOG" ]
rg -q 'project-build.no-test-schemes' "$work/out"

rm "$projects/App/xcshareddata/xcschemes/App.xcscheme" \
	"$projects/$newline_project/xcshareddata/xcschemes/Newline.xcscheme"
if run_stage build >"$work/out" 2>"$work/err"; then
	printf 'FAIL: build 대상 없음이 성공함\n' >&2
	exit 1
else
	result=$?
fi
[ "$result" -eq 2 ] && rg -q 'project-build.no-schemes' "$work/err"

rm -rf "$workspace"
if run_stage build >"$work/out" 2>"$work/err"; then exit 1; else result=$?; fi
[ "$result" -eq 2 ] && rg -q 'project-build.missing-workspace' "$work/err"

if run_project build extra >"$work/out" 2>"$work/err"; then exit 1; else result=$?; fi
[ "$result" -eq 2 ] && rg -q 'common.invalid-input' "$work/err"
printf 'PASS: project-build run\n'
