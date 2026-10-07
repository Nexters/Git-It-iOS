# Tuist 매니페스트와의 일치

[Git It iOS 디렉터리·파일 컨벤션](../directory-file.md)의 규칙 문서입니다.

- 실제 폴더 경로와 `*ModuleName.swift`의 `sourceDirectory` 계산 결과는 항상 같아야
  합니다.
- 폴더를 옮기거나 이름을 바꾸면 매니페스트를 **같은 커밋에서** 갱신합니다.
- `sourceDirectory`는 각 `ModuleName` enum의 연산 프로퍼티에서 target 이름 앞의
  패키지명을 제거해 계산하며, 문자열을 직접 적어 우회하지 않습니다
  ([네이밍 컨벤션 — 패키지 문맥과 Target 이름](../naming.md#4-패키지-문맥)).
- 계산한 경로는 `Target.module` 또는 `Target.testModule`의 필수 `sourceDirectory`
  인자로 전달합니다. 테스트 target은 §3.3의 `Tests/<역할>/` 아래에 배치합니다.
- 형태 폴더나 타입 패밀리 폴더를 추가할 때 source glob은 바꾸지 않습니다. 공통 Tuist
  helper는 전달받은 경로에 `/**`만 붙이며, target 이름을 glob의 기본값으로 사용하거나
  별도 폴더명을 덧붙이지 않습니다.
