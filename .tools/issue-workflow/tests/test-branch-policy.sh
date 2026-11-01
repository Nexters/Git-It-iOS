#!/bin/sh
# shellcheck disable=SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
. "$module/core/branch-policy.sh"

tab=$(printf '\t')
lanes="project${tab}AGENTS.md
project${tab}.tools/
ios${tab}app-code/
ios${tab}.tools/design-rules/config/"
domains=$(branch_policy_domains "$lanes")

assert_equal() {
	[ "$1" = "$2" ] || {
		printf 'FAIL: 기대 %s, 실제 %s\n' "$2" "$1" >&2
		exit 1
	}
}

assert_parse_fails() {
	if branch_policy_parse "$1" "$domains" >/dev/null; then
		printf 'FAIL: %s는 이름 형식이 틀려야 합니다\n' "$1" >&2
		exit 1
	fi
}

# 브랜치 이름을 번호, 도메인과 내용으로 나눕니다.
assert_equal "$(branch_policy_parse feature/44-project-adopt-issue-pr-workflow "$domains")" '44 project adopt-issue-pr-workflow'
assert_equal "$(branch_policy_parse feature/7-ios-home "$domains")" '7 ios home'

# 번호, 레인 표의 도메인과 kebab-case 내용이 모두 있어야 합니다.
for invalid in \
	feature/home-screen \
	feature/44 \
	feature/44-project \
	feature/44-project- \
	feature/44-unknown-home \
	feature/44-ios-Home \
	feature/44-ios-home--screen \
	feature/x44-ios-home \
	feature/ \
	develop; do
	assert_parse_fails "$invalid"
done

# 도메인은 목록의 값과 정확히 같아야 합니다.
branch_policy_has_domain ios "$domains"
for unknown in '' i android; do
	if branch_policy_has_domain "$unknown" "$domains"; then
		printf "FAIL: '%s'는 없는 도메인이어야 합니다\n" "$unknown" >&2
		exit 1
	fi
done

# 폴더는 접두어로, 파일은 전체로 맞추고 가장 긴 경로가 이깁니다.
assert_equal "$(branch_policy_lane_of AGENTS.md "$lanes")" project
assert_equal "$(branch_policy_lane_of app-code/Projects/App.swift "$lanes")" ios
assert_equal "$(branch_policy_lane_of .tools/ci/bin/run.sh "$lanes")" project
assert_equal "$(branch_policy_lane_of .tools/design-rules/config/allowed "$lanes")" ios
assert_equal "$(branch_policy_lane_of docs/conventions/sample.md "$lanes")" ''
assert_equal "$(branch_policy_lane_of AGENTS.md.bak "$lanes")" ''
assert_equal "$(branch_policy_lane_of app-code-backup/App.swift "$lanes")" ''

# 판정 표
assert_equal "$(branch_policy_decide '' "$lanes" '' '')" detached
assert_equal "$(branch_policy_decide main "$lanes" '' '')" protected
assert_equal "$(branch_policy_decide develop "$lanes" '' docs/a.md)" protected
assert_equal "$(branch_policy_decide hotfix/crash "$lanes" '' app-code/A.swift)" allow
assert_equal "$(branch_policy_decide release/v1.2.3 "$lanes" '' AGENTS.md)" allow
assert_equal "$(branch_policy_decide feature/home-screen "$lanes" '' app-code/A.swift)" invalid-name
assert_equal "$(branch_policy_decide feature/9-ios-home "$lanes" MISSING app-code/A.swift)" issue-missing
assert_equal "$(branch_policy_decide feature/9-ios-home "$lanes" CLOSED app-code/A.swift)" issue-closed
assert_equal "$(branch_policy_decide feature/9-ios-home "$lanes" OPEN app-code/A.swift)" allow
assert_equal "$(branch_policy_decide feature/9-ios-home "$lanes" OPEN AGENTS.md)" lane:project
assert_equal "$(branch_policy_decide feature/9-project-tool "$lanes" OPEN app-code/A.swift)" lane:ios
assert_equal "$(branch_policy_decide feature/9-ios-home "$lanes" OPEN docs/a.md)" allow
assert_equal "$(branch_policy_decide feature/9-project-tool "$lanes" OPEN specs/001-a/spec.md)" allow
assert_equal "$(branch_policy_decide feature/9-ios-home "$lanes" OPEN '')" allow

# issue 상태를 확인하지 못해도 레인 위반은 막습니다.
assert_equal "$(branch_policy_decide feature/9-ios-home "$lanes" UNKNOWN app-code/A.swift)" allow
assert_equal "$(branch_policy_decide feature/9-ios-home "$lanes" UNKNOWN AGENTS.md)" lane:project
