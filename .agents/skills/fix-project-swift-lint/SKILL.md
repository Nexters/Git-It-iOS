---
name: fix-project-swift-lint
description: sources/Projects 전체에 프로젝트 공개 Swift lint를 실행하고, 보고된 포맷·린트 오류를 소스 동작 변경 없이 교정한 뒤 전체 검사를 다시 통과시킨다. "전체 Swift lint 교정", "sources/Projects lint 오류 수정", "make format 후 남은 린트 해소"를 요청할 때 사용합니다. 특정 변경 파일만 포맷하는 Spec-Kit 마무리 작업에는 사용하지 않습니다.
---

# Projects Swift lint 오류 교정

## 결과

`sources/Projects` 전체 lint가 종료 코드 0과 위반 0건으로 완료되게 한다. 기존
작업 트리와 Git index를 보존하고, lint 대상인 `sources/Projects/**/*.swift`만
수정한다. Markdown 문서(`*.md`)는 삭제·수정·포맷 대상이 아니며, Spec-Kit 산출물이나
`tasks.md` 상태에도 의존하지 않는다.

## 실행 절차

1. 저장소 루트에서 `git status --short`로 staged·unstaged·untracked 상태를 확인한다.
   기존 변경은 사용자 작업으로 간주하고 복귀하지 않는다.
2. `mktemp -d`로 임시 경계를 만들고, 실행 전
   `git diff --cached --binary --no-ext-diff`를 snapshot으로 보존한다.
3. 다음 공개 명령을 그대로 실행하고 stdout, stderr, 종료 상태를 확인한다.

   ```sh
   ./tools/githooks/swift-format/bin/run.sh lint "$(pwd)/sources/Projects"
   ```

4. SwiftPM·Clang module cache의 `Operation not permitted`, 쓰기 권한 또는 network 실패로
   formatter가 시작되지 못했다면 소스 lint 실패로 분류하지 말고 동일한 명령을
   필요한 권한으로 한 번 다시 실행한다.
5. lint 교정 전에 `sources/Projects/**/*.swift`의 단독 `//` 주석을 제거한다.
   `// MARK:` 주석, 코드 뒤에 붙은 주석, 문자열 리터럴 안의 `//`는 보존한다.
   Markdown을 포함한 Swift 외 파일은 이 단계에서 변경하지 않는다.
6. lint 출력의 파일, 행, 열, rule을 기준으로 위반을 묶는다. 대상 파일과
   주변 코드, 해당 패키지 규칙과 컨벤션을 읽고 의미·가시성·타입 설계를 바꾸지
   않는 최소 교정을 `apply_patch`로 적용한다.
7. Swift 교정이 끝나면 프로젝트 공개 진입점으로 전체 Swift 포맷을 실행한다.

   ```sh
   make format-all
   ```

   `format-all`은 `sources/Projects`의 Swift 파일만 처리한다. 변경 파일만 포맷해야
   할 때는 이 스킬이 아니라 `make format-changed`를 사용한다.
8. 3번의 전체 lint를 반복한다. 종료 코드 0과 위반 0건이 동시에 확인될
   때까지 새로 드러난 스타일 위반도 같은 방식으로 교정한다.
9. 최종 변경 Swift 파일에 `git diff --check -- <paths...>`를 실행한다. cached diff를
   다시 저장하고 실행 전 snapshot과 `cmp`해 Git index가 변하지 않았음을 확인한다.

## 중단 조건

- lint 교정이 소스의 의미, API, 가시성 또는 아키텍처 변경을 요구하면 자동으로
  결정하지 말고 해당 파일·rule·필요한 선택을 보고한다.
- 생성 산출물, 서브모듈, `sources/Projects` 밖의 파일이 오류 대상이면 수정하지
  말고 경계 위반을 보고한다.
- 동일한 도구 시작 실패가 권한 재실행 후에도 반복되면 내부 도구를 우회
  호출하지 말고 blocker로 보고한다.

## 금지 사항

- `tools/githooks/swift-format/core/**` 또는 `tools/swift-style/**` 내부 구현을 직접
  호출하지 않는다.
- `*.md`를 삭제하거나 수정하거나 포맷하지 않는다.
- `git add`, `git commit`, index 복구·초기화, 사용자 변경 되돌리기를 하지 않는다.
- 파일 목록을 공백·개행 구분 문자열로 다시 shell argv로 분해하지 않는다.
  경로는 각 argv로 직접 전달하고, 자동 수집이 필요하면 NUL 경계를 보존한다.

## 보고

최종 답변에 최초 lint 위반 수, 수정한 파일, 적용한 교정 유형, 최종 전체
lint, `git diff --check`, Git index 보존 결과를 구분해 보고한다. 도구 실행 실패와
소스 lint 위반을 같은 결과로 보고하지 않는다.
