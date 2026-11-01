#!/bin/sh
# shellcheck disable=SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
. "$test_dir/fixture.sh"

work=$(mktemp -d "${TMPDIR:-/tmp}/issue-workflow-create-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/저장소 경로"
fake_bin="$work/bin"
fixture_create "$root" "$repository" "$fake_bin"
creator="$repository/.tools/issue-workflow/bin/create-issue.sh"

FAKE_GH_LOG="$work/gh.log"
FAKE_GH_BODY="$work/body.md"
PATH="$fake_bin:$PATH"
export FAKE_GH_LOG FAKE_GH_BODY PATH

assert_rejected() {
	assert_code=$1
	shift
	: >"$FAKE_GH_LOG"
	assert_status=0
	"$creator" "$@" 2>"$work/stderr" || assert_status=$?
	[ "$assert_status" -eq 2 ] || {
		printf 'FAIL: %s는 exit 2여야 합니다(실제 %s)\n' "$assert_code" "$assert_status" >&2
		exit 1
	}
	grep -q "오류\[issue-workflow\.$assert_code\]" "$work/stderr" || {
		printf 'FAIL: 진단 %s 누락\n' "$assert_code" >&2
		cat "$work/stderr" >&2
		exit 1
	}
	[ ! -s "$FAKE_GH_LOG" ] || {
		printf 'FAIL: 검사 실패 시 gh를 호출하면 안 됩니다\n' >&2
		exit 1
	}
}

# 제목 없음, 50자 초과, 라벨 규칙 위반은 gh 호출 전에 거부합니다.
title_50='가나다라마바사아자차가나다라마바사아자차가나다라마바사아자차가나다라마바사아자차가나다라마바사아자차'
assert_rejected missing-title --label 'type: bug' --label 'priority: low'
assert_rejected title-too-long --title "${title_50}카" --label 'type: bug' --label 'priority: low'
assert_rejected unknown-label --title 목적 --label 'bug' --label 'priority: low'
assert_rejected duplicate-label --title 목적 --label 'type: bug' --label 'type: chore' --label 'priority: low'
assert_rejected missing-label --title 목적 --label 'type: bug'
assert_rejected unknown-template --title 목적 --label 'type: bug' --label 'priority: low' --template ../secret
assert_rejected missing-body-file --title 목적 --label 'type: bug' --label 'priority: low' --body-file "$work/없음.md"
assert_rejected invalid-input --unknown

# 50자 제목은 받고, 템플릿 본문의 목적 절을 제목으로 채웁니다.
: >"$FAKE_GH_LOG"
"$creator" --title "$title_50" --label 'type: bug' --label 'priority: low' >"$work/stdout"
grep -q 'issues/7$' "$work/stdout"
grep -q -- "--title $title_50" "$FAKE_GH_LOG"
grep -q -- '--label type: bug --label priority: low' "$FAKE_GH_LOG"
sed -n 1,2p "$FAKE_GH_BODY" >"$work/head"
[ "$(cat "$work/head")" = "## 목적
$title_50." ]
if grep -q '^name:' "$FAKE_GH_BODY"; then
	printf 'FAIL: front matter가 본문에 남았습니다\n' >&2
	exit 1
fi

# 어긋남 템플릿의 기본 라벨을 씁니다.
: >"$FAKE_GH_LOG"
"$creator" --title '코드·문서를 컨벤션에 맞춘다' --template mismatch >/dev/null
grep -q -- '--label type: mismatch --label priority: low' "$FAKE_GH_LOG"

# 본문 파일을 주면 템플릿 대신 그대로 씁니다.
printf '직접 쓴 본문\n' >"$work/custom.md"
"$creator" --title 목적 --label 'type: bug' --label 'priority: low' --body-file "$work/custom.md" >/dev/null
[ "$(cat "$FAKE_GH_BODY")" = '직접 쓴 본문' ]
