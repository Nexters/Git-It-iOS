# Effect 테스트

[Git It iOS TCA 컨벤션 — Reducer와 Effect](../effect.md)의 규칙 문서입니다.

- Domain dependency는 initializer로 Test Double을 주입합니다.
- 사용자 입력과 부모 input은 `store.send`, Effect event와 delegate 출력은
  `store.receive`로 검증합니다.
- 상태 변화는 관련 Action을 처리하는 단계에서 명시합니다.
- 배타 상태에서 유효하지 않은 Action이 State나 Effect를 바꾸지 않는지 검증합니다.
- 교체 가능한 요청은 이전 request identity의 늦은 결과를 거부하고 최신 결과만 반영하는지
  검증합니다.
- 동시에 실행되면 안 되는 Effect의 중복 차단, cancellation과 소유 State 제거 시 정리를
  검증합니다.
- mutation은 `committing` 동안 중복 입력과 취소를 차단하고 성공·실패 뒤 정본과 복구
  상태가 일치하는지 검증합니다.
- 취소 가능한 미완료 Effect는 테스트 종료 전에 정의된 취소 Action을 보내고 `finish()`로
  정리합니다. `committing` 상태의 mutation은 취소하지 않고 성공 또는 실패 결과까지
  수신합니다.

테스트 이름, 비동기 종료, Test Double과 target 구성의 공통 규칙은
[테스트 컨벤션](../../test.md)을 따릅니다.
