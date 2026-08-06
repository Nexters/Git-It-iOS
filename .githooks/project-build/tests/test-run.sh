#!/bin/sh
# shellcheck disable=SC2016
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd -P)
work=$(mktemp -d "${TMPDIR:-/tmp}/project-build-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/repository"
newline_project=$(printf 'Line\nBreak')
mkdir -p "$repository/.githooks/pre-commit.d" "$work/bin"
cp -R "$root/.githooks/project-build" "$repository/.githooks/project-build"
cp "$root/.githooks/pre-commit.d/build.sh" \
	"$root/.githooks/pre-commit.d/compile.sh" \
	"$root/.githooks/pre-commit.d/test.sh" \
	"$repository/.githooks/pre-commit.d/"
git -C "$repository" init -q
mkdir -p "$repository/GitIt.xcworkspace" \
	"$repository/Projects/App/xcshareddata/xcschemes" \
	"$repository/Projects/Tests/xcshareddata/xcschemes" \
	"$repository/Projects/Fail/xcshareddata/xcschemes" \
	"$repository/Projects/$newline_project/xcshareddata/xcschemes"
printf '<Scheme><Testables></Testables></Scheme>\n' \
	>"$repository/Projects/App/xcshareddata/xcschemes/App.xcscheme"
printf '<Scheme><Testables><TestableReference/></Testables></Scheme>\n' \
	>"$repository/Projects/Tests/xcshareddata/xcschemes/Tests.xcscheme"
printf '<Scheme><Testables></Testables></Scheme>\n' \
	>"$repository/Projects/Fail/xcshareddata/xcschemes/Fail.xcscheme"
printf '<Scheme><Testables></Testables></Scheme>\n' \
	>"$repository/Projects/$newline_project/xcshareddata/xcschemes/Newline.xcscheme"
printf '%s\n' '#!/bin/sh' \
	'scheme=' \
	'jobs=' \
	'action=' \
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
	'  if [ "$1" = -scheme ]; then scheme=$2; shift 2; else shift; fi' \
	'done' \
	'[ "$jobs" = 1 ] || exit 91' \
	'[ "$index_store" = true ] || exit 92' \
	'printf "%s\t%s\n" "$action" "$scheme" >> "$PROJECT_ACTION_LOG"' \
	'[ "$scheme" != Fail ]' >"$work/bin/xcodebuild"
chmod +x "$work/bin/xcodebuild"

PROJECT_ACTION_LOG="$work/action.log" PATH="$work/bin:$PATH"
GIT_IT_TEST_DESTINATION='platform=iOS Simulator,name=Test Device'
export PROJECT_ACTION_LOG PATH GIT_IT_TEST_DESTINATION

run_stage() (
	stage=$1
	shift
	# Git 훅과 같은 조건이 되도록 fixture 저장소 루트에서 실행합니다.
	cd "$repository"
	"$repository/.githooks/pre-commit.d/$stage.sh" "$@"
)
run_project() (
	# 공개 명령의 입력 계약도 fixture 저장소 안에서 직접 검증합니다.
	cd "$repository"
	"$repository/.githooks/project-build/bin/run.sh" "$@"
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

rm "$repository/Projects/Fail/xcshareddata/xcschemes/Fail.xcscheme"
: >"$PROJECT_ACTION_LOG"
run_stage compile >"$work/out" 2>"$work/err"
[ "$(cat "$PROJECT_ACTION_LOG")" = "$(printf 'build-for-testing\tTests')" ]
rg -q '작업=compile 시도=1 성공=1 실패=0' "$work/out"

: >"$PROJECT_ACTION_LOG"
run_stage test >"$work/out" 2>"$work/err"
[ "$(cat "$PROJECT_ACTION_LOG")" = "$(printf 'test-without-building\tTests')" ]
rg -q '작업=test 시도=1 성공=1 실패=0' "$work/out"

rm "$repository/Projects/Tests/xcshareddata/xcschemes/Tests.xcscheme"
: >"$PROJECT_ACTION_LOG"
run_stage compile >"$work/out" 2>"$work/err"
[ ! -s "$PROJECT_ACTION_LOG" ]
rg -q 'project-build.no-test-schemes' "$work/out"

rm "$repository/Projects/App/xcshareddata/xcschemes/App.xcscheme" \
	"$repository/Projects/$newline_project/xcshareddata/xcschemes/Newline.xcscheme"
if run_stage build >"$work/out" 2>"$work/err"; then
	printf 'FAIL: build 대상 없음이 성공함\n' >&2
	exit 1
else
	result=$?
fi
[ "$result" -eq 2 ] && rg -q 'project-build.no-schemes' "$work/err"

rm -rf "$repository/GitIt.xcworkspace"
if run_stage build >"$work/out" 2>"$work/err"; then exit 1; else result=$?; fi
[ "$result" -eq 2 ] && rg -q 'project-build.missing-workspace' "$work/err"

if run_project build extra >"$work/out" 2>"$work/err"; then exit 1; else result=$?; fi
[ "$result" -eq 2 ] && rg -q 'common.invalid-input' "$work/err"
printf 'PASS: project-build run\n'
