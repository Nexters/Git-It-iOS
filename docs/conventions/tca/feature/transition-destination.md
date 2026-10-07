# 화면 전환 목적지

[Git It iOS TCA 컨벤션 — Feature 분리](../feature.md)의 규칙 문서입니다.

- **Router가 전환 단위로 삼는 목적지는 그 목적지의 상태를 소유하는 Feature 또는
  Feature 조합을 가져야 합니다.** Router가 목적지의 내부 상태와 불변식을 대신 관리하면
  전환 관심사와 화면 관심사가 한 Feature에 섞입니다.
- **화면의 Feature는 흐름의 다음 화면으로 가기 위한 목적지 상태를 갖지 않습니다.**
  소유할 수 있는 목적지는 자신의 수명 안에서 완결되는 sheet·alert뿐이며, 그 경계는
  [Navigation 컨벤션 — Navigation 경계](../navigation/boundary.md)이 소유합니다. 흐름의
  다음 화면으로 이어지는 전환은 `delegate`로 Router에 알립니다.
