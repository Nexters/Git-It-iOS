---
name: speckit-swift-format-run
description: 현재 작업 트리에서 추가 또는 수정된 Swift 파일을 프로젝트 공개 진입점으로 포맷합니다.
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: swift-format:commands/speckit.swift-format.md
---

# 활성 구현 Swift 파일 포맷

## 목적

모든 구현 패키지가 완료된 뒤, 현재 작업 트리에서 추가 또는 수정된 Swift 파일을 프로젝트가
소유한 공개 포맷 진입점으로 정리한다. 생성 산출물, 삭제된 파일과 Git index는 변경하지 않는다.

## 허용 수정 경로

현재 작업 트리에서 추가 또는 수정된 저장소 내부의 실제 `.swift` 파일만 포맷할 수 있다.
디렉터리, glob, 생성 산출물과 삭제된 파일은 대상이 아니다. 활성 `tasks.md`의 파일 경로는
대상 제한에 사용하지 않는다.

## 실행 절차

1. 저장소 루트에서 `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks`를
   한 번 실행하고 JSON의 `FEATURE_DIR`과 `TASKS`를 확인한다. `tasks.md`가 없거나 미완료 구현
   작업이 남아 있으면 포맷하지 않고 `$speckit-implement` 완료 조건을 먼저 충족하도록 보고한다.
2. `git diff --name-only -z --diff-filter=ACMR HEAD -- '*.swift'`와
   `git ls-files --others --exclude-standard -z -- '*.swift'`로 현재 변경 파일을 확인한다. NUL
   경계를 보존하고 두 명령의 결과를 합쳐 대상으로 선택한다.
3. 각 대상이 저장소 내부의 실제 `.swift` 파일이고 생성 산출물이나 삭제된 파일이 아닌지
   확인한다. 대상이 없으면 `swift-format.no-targets` 의미로 건너뛰고 성공으로 보고한다.
4. 다음 공개 경로 판독기로 runner를 구하고, 선택한 각 파일을 별도 argv로 전달한다.

   ```sh
   swift_format_runner=$(./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_SWIFT_FORMAT_RUNNER)
   "$swift_format_runner" format <현재-변경-Swift-파일-경로>...
   ```

5. 실행 전후 `git diff --cached --binary --no-ext-diff` 결과를 별도 임시 파일에 저장하고
   `cmp`로 비교해 Git index가 바뀌지 않았는지 확인한다. 대상 밖 파일에 새 변경이 생기면
   완료로 보고하지 말고 변경 범위와 원인을 제시한다.
6. 대상 파일에 `git diff --check -- <경로>...`를 실행하고, 포맷한 파일·건너뛴 이유·검증
   결과를 한국어로 보고한다.

## 금지 사항

- `tools/githooks/swift-format/core/**` 또는 `tools/swift-style/**` 내부 구현을 직접 호출하지 않는다.
- `git add`, `git commit` 또는 다른 Git index 변경을 실행하지 않는다.
