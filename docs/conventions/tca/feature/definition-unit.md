# 정의 단위 — 관심사

[Git It iOS TCA 컨벤션 — Feature 분리](../feature.md)의 규칙 문서입니다.

**Feature 하나의 정의 단위는 하나의 관심사입니다.** 관심사는 함께 변하고 함께 검증되는
상태·전이·Effect의 묶음이고, 그 묶음이 `TestStore` 하나로 독립적으로 검증되면 하나의
Feature입니다(§4). Feature는 관심사별로 나누고 **조합해서** 화면과 흐름을 만듭니다.

- Feature는 SwiftUI `View` 타입, 디자인 프레임이나 화면 수가 아니라 관심사로 나눕니다.
- **화면과 Feature는 1:1로 대응하지 않습니다.** 화면은 관심사가 여럿이면 Feature를
  여럿 조합하고, 관심사가 하나면 Feature 하나만 갖습니다. 1:1은 규칙이 아니라 관심사가
  하나인 화면에서 나오는 결과입니다.
- **Feature는 화면 없이 존재할 수 있습니다.** 진입 준비, 이탈 판단처럼 화면을 갖지 않는
  관심사도 정상적인 Feature 형태이며 예외가 아닙니다. 화면이 없는 준비 Feature는 그
  준비가 필요한 여러 Router가 각각 조합합니다.
- **Router-Feature도 관심사 하나입니다.** Router의 관심사는 화면 집합이 아니라 화면
  전환 자체입니다. Router는 전환과 무관한 관심사를 함께 쥐지 않고 별개 Feature로
  조합하며, Router의 관심사 범위는
  [Navigation 컨벤션 — Router-Feature와 화면 전환 소유](../navigation/router.md)이
  소유합니다.
- 같은 관심사 안의 loading, loaded, empty, confirmation과 오류 표현은 별도 Feature가
  아니라 하나의 Feature가 소유하는 State 변형입니다.
- 여러 화면으로 이어지는 흐름을 하나의 Feature가 직접 담지 않습니다. 흐름은
  Router-Feature가 조합합니다.

## 관심사 판별

다음 중 하나 이상을 소유하면 독립된 관심사로 봅니다.

- Use Case 입력, 제출 가능 여부 또는 목적지 결정처럼 제품 동작을 바꾸는 상태
- Action에 따른 상태 전이와 독립적으로 검증할 가치가 있는 불변식
- 비동기 작업, 오류 복구, validation 또는 cancellation 수명
- 화면 재진입 뒤 보존하거나 다른 화면·부모가 관찰해야 하는 사용자 입력과 진행 상태
- 다른 관심사와 겹치지 않는 자신만의 Use Case 의존성

**상태가 비어 있어도 독립된 판단 규칙과 그 판단의 `delegate` 출력을 소유하면 관심사로
인정합니다.** 여러 신호를 모아 흐름 이탈 여부만 판단하는 Feature가 여기에 해당합니다.
관심사의 하한은 State의 크기가 아니라 **그 판단을 단독으로 검증할 수 있는지**입니다.

관심사가 아닌 것은 다음과 같습니다. 누름 애니메이션, geometry 측정, 일시적인 highlight,
부모 State에서 완전히 계산되는 표시 값, callback만 전달하는 행, 부모 State를 읽고
SwiftUI `Binding` 하나로 해결되는 텍스트 필드·토글입니다.
