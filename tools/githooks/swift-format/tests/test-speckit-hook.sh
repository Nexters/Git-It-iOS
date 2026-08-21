#!/bin/sh
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
root=$(CDPATH='' cd -- "$test_dir/../../../.." && pwd -P)
extension_root="$root/.specify/extensions/swift-format"
extension_manifest="$extension_root/extension.yml"
hook_config="$root/.specify/extensions.yml"
skill_file="$root/.agents/skills/speckit-swift-format-run/SKILL.md"
paths="$root/tools/repository-paths/bin/repository-paths.sh"

# 설치 확장, 훅 명령과 Codex 스킬이 같은 명령 ID를 공유해야 합니다.
[ -f "$extension_manifest" ]
[ -f "$hook_config" ]
[ -f "$skill_file" ]
rg -q '^  id: swift-format$' "$extension_manifest"
rg -q '^    - name: speckit\.swift-format\.run$' "$extension_manifest"
rg -q '^  after_implement:$' "$extension_manifest"
rg -q '^    command: speckit\.swift-format\.run$' "$extension_manifest"
rg -q '^[[:space:]]+command: speckit\.swift-format\.run$' "$hook_config"
rg -q '^name: speckit-swift-format-run$' "$skill_file"

# 생성된 스킬은 내부 구현 대신 저장소의 공개 Swift 포맷 진입점을 사용해야 합니다.
rg -q 'check-prerequisites\.sh --json --require-tasks --include-tasks' "$skill_file"
rg -q 'GIT_IT_SWIFT_FORMAT_RUNNER' "$skill_file"
runner=$("$paths" --absolute GIT_IT_SWIFT_FORMAT_RUNNER)
[ -x "$runner" ]

printf 'PASS: speckit swift-format hook\n'
