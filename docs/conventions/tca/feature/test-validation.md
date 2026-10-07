# 정의 단위의 검증 — 단위 테스트

[Git It iOS TCA 컨벤션 — Feature 분리](../feature.md)의 규칙 문서입니다.

§2가 관심사 판단이라면 이 절은 그 판단의 검증입니다. **하나의 Feature는 그 자체로
독립적이고 간결한 단위 테스트가 성립하는 크기여야 합니다.** `TestStore` 사용 방법과
취소·비동기 검증 규칙은 [Effect 컨벤션 — Effect 테스트](../effect/testing.md)·
[테스트 컨벤션](../../test.md)이 소유하며, 이 절은 테스트 작성 난이도를 정의 단위의
신호로 읽는 기준만 정의합니다.

- **주입할 Test Double 수가 분리 신호입니다.** 하나의 Feature를 테스트하려고 주입해야
  하는 Use Case가 계속 늘어나면 그 Feature가 서로 다른 관심사를 함께 소유하고 있다는
  신호로 봅니다. 관심사별로 나누고 각각 자신에게 필요한 Use Case만 주입받게 합니다.
- **화면 관심사 Feature 테스트의 종착점은 `delegate` 방출입니다.** 다음 화면이 무엇인지
  검증하지 않고, 로직 수행 결과로 약속된 `delegate`가 방출되는 것까지만 검증합니다. 그
  `delegate`가 어떤 화면 전환이 되는지는 Router-Feature 테스트가 검증합니다
  ([Navigation 컨벤션 — Router-Feature와 화면 전환 소유](../navigation/router.md)).
  화면 Feature 테스트가 라우팅 결과를 검증해야 한다면 그 화면이 전환 관심사를 함께
  쥐고 있다는 뜻입니다.
- **지속되는 Effect를 소유한 관심사는 취소까지 검증할 수 있는 크기로 캡슐화합니다.**
  타이머, 폴링, 장기 observation처럼 수명이 있는 Effect는 그 Effect를 소유한 Feature의
  `TestStore`에서 시작, 결과 수신과 취소를 모두 검증할 수 있어야 합니다. 취소 정책
  자체는 [Effect 컨벤션 — 취소와 mutation](../effect/cancellation.md)가 소유합니다.
- **테스트가 성립하지 않는 분리도 신호입니다.** 보낼 Action이 없고 검증할 상태 전이도
  없어 `TestStore`를 세울 이유가 없는 단위는 Feature가 아니라 화면 전용 서브뷰 또는
  UIComponent입니다.
