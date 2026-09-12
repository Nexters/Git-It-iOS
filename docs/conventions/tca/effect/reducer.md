# Reducer 책임

[Git It iOS TCA 컨벤션 — Reducer와 Effect](../effect.md)의 규칙 문서입니다.

- Reducer는 현재 State와 Action을 해석해 State를 동기적으로 전이하고 실행할 Effect를
  반환합니다.
- 화면 상태를 바꾸는 판단, 사용자 의도 해석과 유효하지 않은 입력 차단은 Reducer가
  소유합니다.
- Reducer나 View 안에서 `Task`를 만들거나 Use Case, `URLSession`,
  `NotificationCenter` 같은 외부 작업을 직접 실행하지 않습니다.
- 오류를 무시하거나 View가 Domain 오류를 직접 해석하게 하지 않습니다.
