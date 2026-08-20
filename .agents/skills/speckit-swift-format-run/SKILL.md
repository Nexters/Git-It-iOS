---
name: speckit-swift-format-run
description: 활성 tasks.md에 명시된 현재 변경 Swift 파일만 프로젝트 공개 진입점으로 포맷합니다.
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: swift-format:commands/speckit.swift-format.md
---

# 활성 구현 Swift 파일 포맷

## 목적

모든 구현 패키지가 완료된 뒤, 활성 `tasks.md`가 허용한 현재 변경 Swift 파일만 프로젝트가
소유한 공개 포맷 진입점으로 정리한다. 다른 파일과 Git index는 변경하지 않는다.

## 허용 수정 경로

활성 `tasks.md`의 구현 작업에 정확한 저장소 상대경로로 명시되어 있고 현재 작업 트리에서
추가 또는 수정된 `.swift` 파일만 포맷할 수 있다. 디렉터리, glob, 생성 산출물, 삭제된 파일,
활성 작업에 없는 사용자 변경은 대상이 아니다.

## 실행 절차

1. 저장소 루트에서 `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks`를
   한 번 실행하고 JSON의 `FEATURE_DIR`과 `TASKS`를 확인한다. `tasks.md`가 없거나 미완료 구현
   작업이 남아 있으면 포맷하지 않고 `$speckit-implement` 완료 조건을 먼저 충족하도록 보고한다.
2. `tasks.md`의 작업 설명에서 정확한 저장소 상대경로로 적힌 `.swift` 파일만 허용 목록으로
   수집한다. 디렉터리나 wildcard를 파일 권한으로 확장하지 않는다.
3. `git diff --name-only -z --diff-filter=ACMR HEAD -- '*.swift'`와
   `git ls-files --others --exclude-standard -z -- '*.swift'`로 현재 변경 파일을 확인한다. NUL
   경계를 보존하고, 허용 목록과 현재 변경 목록의 교집합만 대상으로 선택한다.
4. 각 대상이 저장소 내부의 실제 `.swift` 파일이고 `tasks.md`에 적힌 경로와 정확히 일치하는지
   다시 확인한다. 대상이 없으면 `swift-format.no-targets` 의미로 건너뛰고 성공으로 보고한다.
5. 다음 공개 경로 판독기로 runner를 구하고, 선택한 각 파일을 별도 argv로 전달한다.

   ```sh
   swift_format_runner=$(./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_SWIFT_FORMAT_RUNNER)
   "$swift_format_runner" format <허용된-파일-경로>...
   ```

6. 실행 전후 `git diff --cached --binary --no-ext-diff` 결과를 별도 임시 파일에 저장하고
   `cmp`로 비교해 Git index가 바뀌지 않았는지 확인한다. 대상 밖 파일에 새 변경이 생기면
   완료로 보고하지 말고 변경 범위와 원인을 제시한다.
7. 대상 파일에 `git diff --check -- <경로>...`를 실행하고, 포맷한 파일·건너뛴 이유·검증
   결과를 한국어로 보고한다.

## 금지 사항

- `tools/githooks/swift-format/core/**` 또는 `tools/swift-style/**` 내부 구현을 직접 호출하지 않는다.
- `git add`, `git commit` 또는 다른 Git index 변경을 실행하지 않는다.
- 활성 작업에서 허용하지 않은 파일을 정리한다는 이유로 포맷하지 않는다.
