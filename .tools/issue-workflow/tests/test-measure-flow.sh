#!/bin/sh
# shellcheck disable=SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
. "$test_dir/fixture.sh"

work=$(mktemp -d "${TMPDIR:-/tmp}/issue-workflow-measure-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/저장소 경로"
fake_bin="$work/bin"
fixture_create "$root" "$repository" "$fake_bin"
measure="$repository/.tools/issue-workflow/bin/measure-flow.sh"
branch=feature/9-project-tool

FAKE_GH_LOG="$work/gh.log"
FAKE_LABEL_FILE="$work/label"
FAKE_ISSUE_BRANCHES=$branch
PATH="$fake_bin:$PATH"
export FAKE_GH_LOG FAKE_LABEL_FILE FAKE_ISSUE_BRANCHES PATH

run_measure() {
	: >"$FAKE_GH_LOG"
	run_status=0
	"$measure" "$@" >"$work/stdout" 2>"$work/stderr" || run_status=$?
}

assert_status() {
	[ "$run_status" -eq "$1" ] || {
		printf 'FAIL: 기대 exit %s, 실제 exit %s\n' "$1" "$run_status" >&2
		cat "$work/stderr" >&2
		exit 1
	}
}

assert_row() {
	grep -q "^| $1 .*| $2 |" "$work/stdout" || {
		printf "FAIL: '%s' 행의 결과가 '%s'가 아닙니다\n" "$1" "$2" >&2
		cat "$work/stdout" >&2
		exit 1
	}
}

assert_no_branch_created() {
	if grep -q 'issue develop' "$FAKE_GH_LOG"; then
		printf 'FAIL: 측정은 브랜치를 내면 안 됩니다\n' >&2
		exit 1
	fi
}

assert_no_writes() {
	assert_no_branch_created
	if grep -q '/labels' "$FAKE_GH_LOG"; then
		printf 'FAIL: --label-probe 없이는 쓰면 안 됩니다\n' >&2
		exit 1
	fi
}

# 입력은 gh 조회 전에 거부합니다.
run_measure
assert_status 2
grep -q '오류\[issue-workflow.invalid-input\]' "$work/stderr"
run_measure --branch "$branch" --repeat 0
assert_status 2
run_measure --branch develop
assert_status 2
grep -q '오류\[issue-workflow.invalid-branch-name\]' "$work/stderr"
[ ! -s "$FAKE_GH_LOG" ]

# 기본 실행은 판정과 시간을 재지만 GitHub에 쓰지 않습니다.
run_measure --branch "$branch" --repeat 2
assert_status 0
assert_row 'gh 조회 1회(기준)' 통과
assert_row '편집 전 검사, 캐시 없음' 통과
assert_row '편집 전 검사, 캐시 있음' 통과
assert_row 'issue 문맥 읽기' 통과
assert_row '같은 레인 차단' 통과
assert_row '다른 레인 통과' 통과
assert_row 'gh 인증 실패 차단' 통과
assert_no_writes

# PR을 연 브랜치를 놓치던 사고: 차단이 뚫려도 실제 브랜치를 내지 않고 실패합니다.
FAKE_ISSUE_BRANCHES=''
run_measure --branch "$branch" --repeat 2
assert_status 1
assert_row '같은 레인 차단' '판정 불일치'
assert_row 'issue 문맥 읽기' 통과
grep -q '오류\[issue-workflow.measure-mismatch\]' "$work/stderr"
assert_no_branch_created
FAKE_ISSUE_BRANCHES=$branch

# 판정이 어긋나면 --label-probe를 줘도 라벨을 달지 않습니다.
FAKE_ISSUE_BRANCHES=''
run_measure --branch "$branch" --repeat 1 --label-probe
assert_status 1
assert_no_writes
FAKE_ISSUE_BRANCHES=$branch

# --label-probe는 status: 라벨을 달아 실제 차단을 재고 끝나면 뗍니다.
run_measure --branch "$branch" --repeat 1 --label-probe
assert_status 0
assert_row 'status: 라벨 차단, 브랜치 시작' 통과
assert_row 'status: 라벨 차단, 문맥 읽기' 통과
grep -q '^api repos/{owner}/{repo}/issues/9/labels -f labels\[\]=status: on-hold --silent$' "$FAKE_GH_LOG"
grep -q '^api --method DELETE repos/{owner}/{repo}/issues/9/labels/status%3A%20on-hold --silent$' "$FAKE_GH_LOG"
[ ! -e "$FAKE_LABEL_FILE" ]
assert_no_branch_created

# 라벨을 달지 못하면 실패하고 뗄 것도 없습니다.
FAKE_LABEL_ADD_FAIL=true
export FAKE_LABEL_ADD_FAIL
run_measure --branch "$branch" --repeat 1 --label-probe
assert_status 1
grep -q '오류\[issue-workflow.label-write-failed\]' "$work/stderr"
if grep -q '^api --method DELETE' "$FAKE_GH_LOG"; then
	printf 'FAIL: 달지 않은 라벨을 떼면 안 됩니다\n' >&2
	exit 1
fi
unset FAKE_LABEL_ADD_FAIL

# 라벨을 떼지 못하면 사람이 뗄 수 있게 알리고 실패합니다.
FAKE_LABEL_REMOVE_FAIL=true
export FAKE_LABEL_REMOVE_FAIL
run_measure --branch "$branch" --repeat 1 --label-probe
assert_status 1
grep -q '오류\[issue-workflow.label-left\]' "$work/stderr"
grep -q 'status: on-hold' "$work/stderr"
unset FAKE_LABEL_REMOVE_FAIL
rm -f "$FAKE_LABEL_FILE"

# --summary는 같은 표를 파일 끝에 더합니다.
printf '기존 요약\n' >"$work/summary"
run_measure --branch "$branch" --repeat 1 --summary "$work/summary"
assert_status 0
grep -q '^기존 요약$' "$work/summary"
grep -q '^| 같은 레인 차단 ' "$work/summary"
