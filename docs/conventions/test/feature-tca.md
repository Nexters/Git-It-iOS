# Feature와 TCA 테스트

[Git It iOS 테스트 컨벤션](../test.md)의 규칙 문서입니다.

Feature 테스트는 Swift Testing 안에서 TCA의 `TestStore`를 사용하고, 초기 State와
initializer로 주입할 Domain Use Case를 테스트 본문에서 명시합니다. 외부 의존성의 입력과
호출 횟수는 §5의 Test Double snapshot으로 별도 검증합니다.

`TestStore`로 무엇을 검증해야 하는지 — 상태 전이, Effect event, 취소, 늦은 응답과
delegate 출력 — 와 Effect 취소의 production 규칙은
[TCA Effect 컨벤션 — Effect 테스트](../tca/effect/testing.md)이 소유합니다.

Feature 테스트의 입력은 HTTP 상태 코드나 DTO fixture가 아니라 Domain 결과와 Domain
오류입니다.
