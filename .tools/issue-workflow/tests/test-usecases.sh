#!/bin/sh
# shellcheck disable=SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
. "$module/core/branch-policy.sh"
. "$module/core/issue-policy.sh"
. "$module/core/issue-gate.sh"
. "$module/core/check-branch.sh"
. "$module/core/create-issue.sh"
. "$module/core/start-branch.sh"
. "$module/core/read-issue.sh"

work=$(mktemp -d "${TMPDIR:-/tmp}/issue-workflow-usecase-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
calls="$work/calls"
run_status=0

tab=$(printf '\t')
lanes="project${tab}.tools/
ios${tab}app-code/"
known_labels="type:${tab}type: bug${tab}required
priority:${tab}priority: low${tab}required"

log_call() {
	printf '%s\n' "$*" >>"$calls"
}

assert_run() {
	[ "$run_status" -eq "$1" ] || {
		printf 'FAIL: 기대 exit %s, 실제 %s\n' "$1" "$run_status" >&2
		exit 1
	}
	[ "$(cat "$calls")" = "$2" ] || {
		printf 'FAIL: 호출 순서가 다릅니다\n기대:\n%s\n실제:\n' "$2" >&2
		cat "$calls" >&2
		exit 1
	}
}

# 각 fake port는 호출을 기록하고 테스트가 정한 결과를 돌려줍니다.
fake_relative() {
	log_call relative
	[ "$relative_result" != FAIL ] || return 1
	printf '%s\n' "$relative_result"
}

fake_ignored() {
	log_call ignored "$1"
	[ "$ignored_result" = true ]
}

fake_lanes() {
	log_call lanes "$1"
	[ "$lanes_result" != FAIL ] || return 1
	printf '%s\n' "$lanes_result"
}

fake_branch() {
	log_call branch
	[ "$branch_result" != FAIL ] || return 1
	printf '%s\n' "$branch_result"
}

fake_cached_state() {
	log_call state "$3"
	[ "$state_result" != FAIL ] || return 1
	printf '%s\n' "$state_result"
}

fake_report() {
	log_call report "$1"
}

fake_known() {
	log_call known "$1"
	[ "$known_result" != FAIL ] || return 1
	printf '%s\n' "$known_result"
}

fake_template_labels() {
	log_call template-labels "$1"
	printf 'priority: low\n'
}

fake_template_body() {
	log_call template-body "$1"
	[ "$template_body_result" != FAIL ] || return 1
	printf '템플릿\n'
}

fake_fill() {
	log_call fill "$2"
	cat "$1"
}

fake_create() {
	log_call create "$1" "$2"
	log_call body "$(cat "$2")"
}

fake_state() {
	log_call state "$1"
	[ "$state_result" != FAIL ] || return 1
	printf '%s\n' "$state_result"
}

fake_labels() {
	log_call labels "$1"
	[ "$labels_result" != FAIL ] || return 1
	printf '%s\n' "$labels_result"
}

fake_branches() {
	log_call branches "$1"
	[ "$branches_result" != FAIL ] || return 1
	printf '%s\n' "$branches_result"
}

fake_develop() {
	log_call develop "$1" "$2"
	[ "$develop_result" != FAIL ] || return 1
}

fake_context() {
	log_call context "$1"
	[ "$context_result" != FAIL ] || return 1
	printf 'issue 문맥\n'
}

run_check() {
	: >"$calls"
	run_status=0
	check_branch_run /repository "$work" "$1" "$2" "$3" lane.md \
		fake_relative fake_ignored fake_lanes fake_branch fake_cached_state fake_report || run_status=$?
}

run_create() {
	: >"$calls"
	run_status=0
	create_issue_run "$1" 5 "$2" template.md "$3" label.md "$work" \
		fake_known fake_template_labels fake_template_body fake_fill fake_create fake_report || run_status=$?
}

run_start() {
	: >"$calls"
	run_status=0
	start_branch_run "$1" "$2" "$3" lane.md "$work" \
		fake_lanes fake_state fake_labels fake_branches fake_develop fake_report >"$work/stdout" || run_status=$?
}

run_read() {
	: >"$calls"
	run_status=0
	read_issue_run "$1" "$2" lane.md "$work" \
		fake_lanes fake_branch fake_state fake_labels fake_context fake_report >"$work/stdout" || run_status=$?
}

relative_result=.tools/a.sh
ignored_result=false
lanes_result=$lanes
branch_result=feature/44-project-tool
state_result=OPEN

# 저장소 밖 파일은 다른 port를 부르지 않고 통과합니다.
relative_result=FAIL
run_check /outside false ''
assert_run 0 'relative'
relative_result=.tools/a.sh

# Git이 무시하는 파일은 레인과 브랜치를 읽기 전에 통과합니다.
ignored_result=true
run_check .tools/a.sh false ''
assert_run 0 'relative
ignored .tools/a.sh'
ignored_result=false

# 레인 표를 못 읽으면 브랜치를 읽기 전에 멈춥니다.
lanes_result=FAIL
run_check .tools/a.sh false ''
assert_run 1 'relative
ignored .tools/a.sh
lanes lane.md
report missing-lane-table'
lanes_result=$lanes

# 정상 흐름은 대상, 레인, 브랜치, issue 순서로 읽고 진단을 내지 않습니다.
run_check .tools/a.sh false ''
assert_run 0 'relative
ignored .tools/a.sh
lanes lane.md
branch
state 44'

# 대상 파일이 없으면 경로 port를 건너뛰고, 지정한 브랜치는 현재 브랜치를 읽지 않습니다.
run_check '' true feature/7-ios-home
assert_run 0 'lanes lane.md
state 7'

# 현재 브랜치를 못 읽으면 판정하지 않고 멈춥니다.
branch_result=FAIL
run_check .tools/a.sh false ''
assert_run 1 'relative
ignored .tools/a.sh
lanes lane.md
branch'

# 형식에 맞지 않는 브랜치는 issue를 조회하지 않고 막습니다.
branch_result=develop
run_check .tools/a.sh false ''
assert_run 2 'relative
ignored .tools/a.sh
lanes lane.md
branch
report protected'
branch_result=feature/44-project-tool

# 닫힌 issue와 다른 레인은 exit 2로 막습니다.
state_result=CLOSED
run_check .tools/a.sh false ''
assert_run 2 'relative
ignored .tools/a.sh
lanes lane.md
branch
state 44
report issue-closed'
state_result=OPEN

relative_result=app-code/A.swift
run_check app-code/A.swift false ''
assert_run 2 'relative
ignored app-code/A.swift
lanes lane.md
branch
state 44
report lane:ios'
relative_result=.tools/a.sh

# issue 상태를 못 읽으면 경고만 내고 레인 검사는 계속합니다.
state_result=FAIL
run_check .tools/a.sh false ''
assert_run 0 'relative
ignored .tools/a.sh
lanes lane.md
branch
state 44
report issue-state-unavailable'

relative_result=app-code/A.swift
run_check app-code/A.swift false ''
assert_run 2 'relative
ignored app-code/A.swift
lanes lane.md
branch
state 44
report issue-state-unavailable
report lane:ios'
relative_result=.tools/a.sh
state_result=OPEN

known_result=$known_labels
template_body_result=ok

# 긴 제목은 라벨 표를 읽기 전에 멈춥니다.
run_create 여섯글자제목 'type: bug' ''
assert_run 2 'report title-too-long'

# 라벨 표를 못 읽으면 템플릿과 gh를 쓰지 않습니다.
known_result=FAIL
run_create 목적 'type: bug' ''
assert_run 1 'known label.md
report missing-label-table'
known_result=$known_labels

# 라벨 규칙 위반은 본문을 준비하기 전에 멈춥니다.
run_create 목적 '없는 라벨' ''
assert_run 2 'known label.md
template-labels template.md
report unknown:없는 라벨'

# 본문 파일이 없으면 템플릿 본문의 목적 절을 채워 만듭니다.
run_create 목적 'type: bug' ''
assert_run 0 "known label.md
template-labels template.md
template-body template.md
fill 목적
create 목적 $work/body.md
body 템플릿"

# 본문을 준비하지 못하면 issue를 만들지 않습니다.
template_body_result=FAIL
run_create 목적 'type: bug' ''
assert_run 1 'known label.md
template-labels template.md
template-body template.md'
template_body_result=ok

# 본문 파일이 있으면 템플릿 본문을 읽지 않고 그대로 넘깁니다.
printf '직접 쓴 본문\n' >"$work/custom.md"
run_create 목적 'type: bug' "$work/custom.md"
assert_run 0 "known label.md
template-labels template.md
create 목적 $work/custom.md
body 직접 쓴 본문"

# 레인 표를 못 읽으면 issue를 조회하지 않습니다.
lanes_result=FAIL
run_start 9 ios home
assert_run 1 'lanes lane.md
report missing-lane-table'
lanes_result=$lanes

# 도메인과 내용이 틀리면 issue를 조회하지 않습니다.
run_start 9 android home
assert_run 2 'lanes lane.md
report unknown-domain'
run_start 9 ios Home
assert_run 2 'lanes lane.md
report invalid-topic'

# 상태를 못 읽거나 열린 issue가 아니면 브랜치를 내지 않습니다.
state_result=FAIL
run_start 9 ios home
assert_run 1 'lanes lane.md
state 9
report issue-state-unavailable'
state_result=MISSING
run_start 9 ios home
assert_run 2 'lanes lane.md
state 9
report issue-missing'
state_result=CLOSED
run_start 9 ios home
assert_run 2 'lanes lane.md
state 9
report issue-closed'
state_result=OPEN

labels_result='type: bug'
branches_result=''

# status: 라벨이 달린 issue는 브랜치 목록을 읽기 전에 막습니다.
labels_result='type: bug
status: on-hold'
run_start 9 ios home
assert_run 2 'lanes lane.md
state 9
labels 9
report issue-held'
labels_result='type: bug'

# 같은 레인의 브랜치가 남아 있으면 브랜치를 내지 않습니다.
branches_result=feature/9-ios-other
run_start 9 ios home
assert_run 2 'lanes lane.md
state 9
labels 9
branches 9
report issue-in-progress'
branches_result=''

# 라벨이나 브랜치 목록을 읽지 못하면 브랜치를 내지 않습니다.
labels_result=FAIL
run_start 9 ios home
assert_run 1 'lanes lane.md
state 9
labels 9
report issue-state-unavailable'
labels_result='type: bug'

branches_result=FAIL
run_start 9 ios home
assert_run 1 'lanes lane.md
state 9
labels 9
branches 9
report issue-state-unavailable'
branches_result=''

# 브랜치를 내지 못하면 이름을 출력하지 않습니다.
develop_result=FAIL
run_start 9 ios home
assert_run 1 'lanes lane.md
state 9
labels 9
branches 9
develop 9 feature/9-ios-home'
[ ! -s "$work/stdout" ] || {
	printf 'FAIL: 실패한 브랜치 이름을 출력하면 안 됩니다\n' >&2
	exit 1
}
develop_result=ok

# 다른 레인의 브랜치는 막지 않습니다.
branches_result=feature/9-project-tool
run_start 9 ios home
assert_run 0 'lanes lane.md
state 9
labels 9
branches 9
develop 9 feature/9-ios-home'
branches_result=''

# 열린 issue에서 브랜치를 내고 그 이름을 출력합니다.
run_start 9 ios home
assert_run 0 'lanes lane.md
state 9
labels 9
branches 9
develop 9 feature/9-ios-home'
[ "$(cat "$work/stdout")" = feature/9-ios-home ] || {
	printf 'FAIL: 브랜치 이름을 출력해야 합니다\n' >&2
	exit 1
}

context_result=ok

# 레인 표를 못 읽으면 브랜치와 issue를 읽지 않습니다.
lanes_result=FAIL
run_read false ''
assert_run 1 'lanes lane.md
report missing-lane-table'
lanes_result=$lanes

# issue 브랜치가 아니면 issue를 조회하지 않습니다.
branch_result=develop
run_read false ''
assert_run 2 'lanes lane.md
branch
report invalid-branch-name'
branch_result=feature/44-project-tool

# 현재 브랜치의 번호로 상태, 라벨, 문맥 순서로 읽습니다.
run_read false ''
assert_run 0 'lanes lane.md
branch
state 44
labels 44
context 44'
[ "$(cat "$work/stdout")" = 'issue 문맥' ] || {
	printf 'FAIL: issue 문맥을 출력해야 합니다\n' >&2
	exit 1
}

# 지정한 브랜치는 현재 브랜치를 읽지 않습니다.
run_read true feature/9-ios-home
assert_run 0 'lanes lane.md
state 9
labels 9
context 9'

# 닫혔거나 status: 라벨이 달린 issue는 문맥을 내지 않습니다.
state_result=CLOSED
run_read true feature/9-ios-home
assert_run 2 'lanes lane.md
state 9
report issue-closed'
state_result=OPEN

labels_result='status: blocked'
run_read true feature/9-ios-home
assert_run 2 'lanes lane.md
state 9
labels 9
report issue-held'
labels_result='type: bug'

# 문맥을 읽지 못하면 실패합니다.
context_result=FAIL
run_read true feature/9-ios-home
assert_run 1 'lanes lane.md
state 9
labels 9
context 9
report issue-state-unavailable'
context_result=ok

printf 'PASS: issue-workflow 유스케이스 순서 회귀\n'
