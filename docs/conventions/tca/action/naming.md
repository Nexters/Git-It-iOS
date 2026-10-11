# Action 이름과 payload

[Git It iOS TCA 컨벤션 — Action](../action.md)의 규칙 문서입니다.

- View Action은 `retryTapped`, `refreshRequested`, `deletionConfirmed`처럼 관찰된 사용자
  사건이나 lifecycle 사건으로 이름을 짓습니다.
- `fetchItems`, `deleteItem`, `navigateToDetail`, `showError`처럼 앞으로 할 작업이나
  구현 결정을 View Action 이름으로 사용하지 않습니다.
- 성공과 실패를 하나의 `Result`로 전달하는 Effect event는
  `itemsLoadFinished`처럼 완료된 작업을 표현합니다. `Response`는 실제 응답 객체가
  Feature 경계에서 의미를 가질 때만 사용합니다.
- Delegate는 `detailRequested`, `itemSelected`, `authenticationRequired`처럼
  Feature가 외부에 알리는 의미를 표현하고 `pushDetail`처럼 App의 전환 방식을
  명령하지 않습니다.
- Delegate payload는 App이 제거될 Child State를 다시 조회하지 않고도 즉시 해석할 수
  있도록 목적지 결정에 필요한 값을 완전하게 전달합니다.
- 사용자가 직접 발생시킬 수 없는 Effect event와 delegate를 View가 보내지 못하게
  Action 접근 경계를 유지합니다.
