#!/bin/sh
# shellcheck disable=SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
paths="$root/.tools/repository-paths/bin/repository-paths.sh"
. "$module/core/convention-reader.sh"
. "$module/core/branch-policy.sh"

work=$(mktemp -d "${TMPDIR:-/tmp}/issue-workflow-reader-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
tab=$(printf '\t')

assert_equal() {
	[ "$1" = "$2" ] || {
		printf 'FAIL: 기대\n%s\n실제\n%s\n' "$2" "$1" >&2
		exit 1
	}
}

# 머리글 이름으로 열을 찾으므로 열 순서가 바뀌어도 읽습니다.
cat >"$work/lanes.md" <<'EOF'
# 문서

| 다른 표 | 값 |
| --- | --- |
| a | b |

| 도메인 | 경로 | 레인 |
| --- | --- | --- |
| `one` | `a.md` · `b/` | 첫째 |
| `two` | `c/` | 둘째 |

| 도메인 | 경로 |
| --- | --- |
| `three` | `d/` |
EOF
assert_equal "$(convention_reader_lanes "$work/lanes.md")" "one${tab}a.md
one${tab}b/
two${tab}c/"

# 첫 열이 빈 행은 위 카테고리를 잇고 필수 여부를 물려받습니다.
cat >"$work/labels.md" <<'EOF'
| 카테고리 | 라벨 | 뜻 |
| --- | --- | --- |
| `type:` (파랑, 필수) | `type: a` | 뜻 |
| | `type: b` | 뜻 |
| `status:` (회색, 선택) | `status: c` | 뜻 |
EOF
assert_equal "$(convention_reader_labels "$work/labels.md")" "type:${tab}type: a${tab}required
type:${tab}type: b${tab}required
status:${tab}status: c${tab}optional"

# 표가 없으면 빈 결과가 아니라 실패합니다.
printf '# 표 없음\n' >"$work/empty.md"
if convention_reader_lanes "$work/empty.md" >/dev/null; then
	printf 'FAIL: 표가 없는 문서는 실패해야 합니다\n' >&2
	exit 1
fi

# 템플릿 본문과 labels 값
cat >"$work/template.md" <<'EOF'
---
name: 작업
labels: "type: a, priority: b"
---
## 목적
<!-- 설명 -->
EOF
assert_equal "$(convention_reader_template_body "$work/template.md")" '## 목적
<!-- 설명 -->'
assert_equal "$(convention_reader_template_labels "$work/template.md")" 'type: a
priority: b'
convention_reader_template_body "$work/template.md" >"$work/body.md"
assert_equal "$(convention_reader_fill_purpose "$work/body.md" '제목 \ & 문장')" '## 목적
제목 \ & 문장.
<!-- 설명 -->'

# 실제 규칙 문서는 도구가 기대하는 값을 그대로 제공해야 합니다.
lane_doc=$("$paths" --absolute GIT_IT_WORKFLOW_LANE_DOC)
label_doc=$("$paths" --absolute GIT_IT_WORKFLOW_LABEL_DOC)
template_root=$("$paths" --absolute GIT_IT_ISSUE_TEMPLATE_ROOT)
lanes=$(convention_reader_lanes "$lane_doc")
assert_equal "$(branch_policy_domains "$lanes")" 'ios
project'
projects_root=$("$paths" GIT_IT_PROJECTS_ROOT)
assert_equal "$(branch_policy_lane_of "$projects_root/App/App.swift" "$lanes")" ios
assert_equal "$(branch_policy_lane_of .tools/package-dependencies/config/source-roots "$lanes")" ios
assert_equal "$(branch_policy_lane_of .tools/ci/bin/pre-push.sh "$lanes")" project
assert_equal "$(branch_policy_lane_of .specify/memory/constitution.md "$lanes")" project
assert_equal "$(branch_policy_lane_of docs/conventions/view.md "$lanes")" ''
assert_equal "$(branch_policy_lane_of specs/001-sample/spec.md "$lanes")" ''

labels=$(convention_reader_labels "$label_doc")
assert_equal "$(printf '%s\n' "$labels" | wc -l | tr -d ' ')" 11
assert_equal "$(printf '%s\n' "$labels" | cut -f1 | sort -u | tr '\n' ' ')" 'priority: status: type: '
assert_equal "$(printf '%s\n' "$labels" | awk -F '\t' '$3 == "required"' | wc -l | tr -d ' ')" 9

# 템플릿의 기본 라벨은 라벨 표에 있고 본문은 세 절이어야 합니다.
for template in task mismatch; do
	sections=$(grep '^## ' "$template_root/$template.md")
	assert_equal "$sections" '## 목적
## 범위(경로)
## 완료 조건'
	template_labels=$(convention_reader_template_labels "$template_root/$template.md")
	while IFS= read -r label; do
		[ -n "$label" ] || continue
		printf '%s\n' "$labels" | cut -f2 | grep -Fxq -- "$label" || {
			printf 'FAIL: 템플릿 라벨 %s가 라벨 표에 없습니다\n' "$label" >&2
			exit 1
		}
	done <<EOF
$template_labels
EOF
done
