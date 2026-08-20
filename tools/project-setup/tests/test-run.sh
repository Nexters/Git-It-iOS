#!/bin/sh
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
module_relative=${module#"$root/"}
work=$(mktemp -d "${TMPDIR:-/tmp}/project-setup-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/한글 저장소"
source_paths="$root/tools/repository-paths/bin/repository-paths.sh"
paths_relative=${source_paths#"$root/"}
config_relative=$("$source_paths" GIT_IT_PATHS_FILE)

# 공백과 한글이 있는 격리 저장소에 공개 명령과 경로 설정을 복제합니다.
mkdir -p "$repository/$module_relative/bin" \
	"$repository/$module_relative/core" \
	"$repository/$(dirname -- "$paths_relative")" \
	"$repository/$(dirname -- "$config_relative")"
cp "$module/bin/run.sh" "$repository/$module_relative/bin/run.sh"
cp "$module/core/"*.sh "$repository/$module_relative/core/"
cp "$source_paths" "$repository/$paths_relative"
cp "$root/$config_relative" "$repository/$config_relative"
repository=$(CDPATH='' cd -- "$repository" && pwd -P)
runner="$repository/$module_relative/bin/run.sh"
paths="$repository/$paths_relative"

workspace_target=$("$paths" GIT_IT_WORKSPACE_PATH)
workspace_link=$("$paths" GIT_IT_WORKSPACE_LINK_PATH)
agent_instructions=$("$paths" GIT_IT_AGENT_INSTRUCTIONS_PATH)
agent_skills=$("$paths" GIT_IT_AGENT_SKILLS_ROOT)
claude_instructions=$("$paths" GIT_IT_CLAUDE_INSTRUCTIONS_LINK_PATH)
claude_skills=$("$paths" GIT_IT_CLAUDE_SKILLS_LINK_PATH)
vscode_workspace=$("$paths" GIT_IT_VSCODE_WORKSPACE_PATH)
specs_root=$("$paths" GIT_IT_SPECS_ROOT)
docs_root=$("$paths" GIT_IT_DOCS_ROOT)

# 링크의 대상과 위치는 구현에 하드코딩하지 않고 중앙 JSON만 소유합니다.
for key in \
	GIT_IT_WORKSPACE_PATH GIT_IT_WORKSPACE_LINK_PATH \
	GIT_IT_AGENT_INSTRUCTIONS_PATH GIT_IT_CLAUDE_INSTRUCTIONS_LINK_PATH \
	GIT_IT_AGENT_SKILLS_ROOT GIT_IT_CLAUDE_SKILLS_LINK_PATH; do
	value=$("$paths" "$key")
	if rg -n -F "$value" "$repository/$module_relative/bin" \
		"$repository/$module_relative/core" >"$work/hardcoded"; then
		printf 'FAIL: 링크 경로가 프로젝트 설정 구현에 하드코딩됨: %s\n' "$key" >&2
		cat "$work/hardcoded" >&2
		exit 1
	else
		result=$?
		[ "$result" -eq 1 ] || exit "$result"
	fi
done

mkdir -p "$repository/$workspace_target" "$repository/$agent_skills" \
	"$repository/$specs_root" "$repository/$docs_root"
printf '# Agent instructions\n' >"$repository/$agent_instructions"

# 기존의 끊어진 workspace 링크도 제거한 뒤 올바른 대상으로 다시 만듭니다.
ln -s '이전/Workspace.xcworkspace' "$repository/$workspace_link"
"$runner" workspace-link
[ -L "$repository/$workspace_link" ]
[ "$(readlink "$repository/$workspace_link")" = "$workspace_target" ]

# 일반 파일은 삭제하지 않고 안정 진단과 함께 실패해야 합니다.
rm -f "$repository/$workspace_link"
printf '보존할 파일\n' >"$repository/$workspace_link"
if "$runner" workspace-link >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 일반 workspace 파일 충돌을 성공으로 반환\n' >&2
	exit 1
else
	result=$?
fi
[ "$result" -eq 2 ]
[ "$(cat "$repository/$workspace_link")" = '보존할 파일' ]
rg -q 'project-setup.path-conflict' "$work/err"
rm -f "$repository/$workspace_link"

# Claude 호환 링크와 두 문서 루트를 포함한 VS Code workspace를 생성합니다.
"$runner" developer-tools
[ "$(readlink "$repository/$claude_instructions")" = "$agent_instructions" ]
[ "$(readlink "$repository/$claude_skills")" = "$agent_skills" ]
[ -f "$repository/$vscode_workspace" ]
[ "$(/usr/bin/plutil -extract folders.0.path raw "$repository/$vscode_workspace")" = "$specs_root" ]
[ "$(/usr/bin/plutil -extract folders.1.path raw "$repository/$vscode_workspace")" = "$docs_root" ]

# 재실행은 기존 Claude 심볼릭 링크를 교체하고 workspace 파일을 갱신합니다.
rm -f "$repository/$claude_instructions" "$repository/$claude_skills"
ln -s '이전-지침.md' "$repository/$claude_instructions"
ln -s '.이전-agent' "$repository/$claude_skills"
printf '{}\n' >"$repository/$vscode_workspace"
"$runner" developer-tools
[ "$(readlink "$repository/$claude_instructions")" = "$agent_instructions" ]
[ "$(readlink "$repository/$claude_skills")" = "$agent_skills" ]
[ "$(/usr/bin/plutil -extract folders.0.path raw "$repository/$vscode_workspace")" = "$specs_root" ]

# 지원하지 않는 동작은 입력 오류로 반환합니다.
if "$runner" unknown >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 알 수 없는 동작을 성공으로 반환\n' >&2
	exit 1
else
	result=$?
fi
[ "$result" -eq 2 ] && rg -q 'common.invalid-input' "$work/err"

printf 'PASS: project setup\n'
