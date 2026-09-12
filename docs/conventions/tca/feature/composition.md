# Feature 조합

[Git It iOS TCA 컨벤션 — Feature 분리](../feature.md)의 규칙 문서입니다.

관심사로 나눈 Feature는 상위 Feature가 조합합니다. 조합의 목적은 상위가 하위의 결과를
해석해 자신의 관심사를 수행하는 것이고, 하위의 내부를 대신 운전하는 것이 아닙니다.

- 상위는 하위 `State`를 자신의 `State` 프로퍼티로 보유하고, 하위 `Action`을 자신의
  `Action` case로 감싸며, `body`에서 `Scope`로 연결합니다.
- **하위는 `delegate`로만 결과를 알립니다.** 상위는 그 `delegate`를 해석해 다른 하위에
  조정 신호(`input`)를 보내거나 자신의 `delegate`로 올립니다. 하위는 자신을 조합하는
  상위가 누구인지 알지 않습니다.
- 상위가 하위의 내부 상태를 직접 바꾸지 않는다는 경계는
  [Navigation 컨벤션 — Router-Feature와 화면 전환 소유](../navigation/router.md)이
  소유합니다.
- **하나의 관심사가 여러 화면이나 흐름에서 쓰이면 그 Feature를 여러 상위가 각각
  조합합니다.** 관심사를 복제하거나 상위마다 다시 구현하지 않습니다.
- 관심사를 나눌지 판단하는 기준은 §2.1이며, 조합 깊이를 늘리는 것 자체가 목적이 아닙니다.
  §2.1의 어느 항목에도 해당하지 않는 하위 View는 [View 컨벤션 — 화면 전용 서브뷰](../../view/screen-subview.md)의
  화면 전용 서브뷰나 [UIComponent 컨벤션](../../ui-component.md)의 재사용 컴포넌트입니다.
