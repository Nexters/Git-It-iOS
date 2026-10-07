# View 내부 선언

[Git It iOS View 내부 선언 컨벤션](../view-declarations.md)의 규칙 문서입니다.

**View가 소유하는 선언은 언제나 그 View의 이름 아래에, 소유 View와 같은 파일에
둡니다.** 파일 최상위로 꺼내지 않고, `{View}+{선언}.swift`처럼 별도 파일로도 나누지
않습니다. 이 규칙은 UIComponent 컴포넌트와 Feature 화면에 동일하게 적용합니다.

`Constant`뿐 아니라 `Style`과 그 밖에 View가 소유하는 모든 보조 선언에 같은 형태를
적용합니다 — **View 선언 뒤의 `private extension {View}` 블록**입니다. `private`을
붙일 수 없는 선언은 View가 소유해서는 안 됩니다(§2.2).
단, Feature의 `State`, `Action`, Reducer와 cancellation ID는 View가 아니라 Feature 타입이
소유하므로 화면 파일로 옮기지 않습니다.

| 선언 | 정의하는 경우 | 접근 수준 |
|---|---|---|
| `enum Constant` | View 내부에서만 의미를 갖는 상수값이 있을 때 | 항상 `private` |
| `enum Style` | UI 컴포넌트에 시각 변형이 존재할 때 | 필요한 최소 수준 |

`Item`, `Control`처럼 View가 소유하는 그 밖의 보조 타입도 같은 규칙으로 중첩합니다.
Feature 화면에는 `Constant`와 화면 전용 렌더링 보조 선언만 둘 수 있으며, 상태·Action을
다시 표현하는 보조 모델은 만들지 않습니다([View 컨벤션 — 공개 생성 경로](../view/display-value-binding-callback.md)).
소유 View가 이름에 문맥을 제공하므로 타입 이름에 View 이름을 반복하지 않습니다.
`ActionButtonStyle`이 아니라 `ActionButton.Style`, `SelectionCardListItem`이 아니라
`SelectionCardList.Item`으로 부릅니다.

한 View의 렌더링 규칙을 읽는 데 필요한 비상태 선언을 한 파일에 모으기 위한 규칙입니다.
`Constant`는 `body`의 수치가 어디서 오는지, `Style`은 변형마다 무엇이 달라지는지를
설명합니다. 표시 값과 `Binding`은 별도 타입으로 감싸지 않고 컴포넌트 저장 프로퍼티에
직접 둡니다.

프리뷰 전용 타입은 View의 계약이 아니므로 중첩 대상이 아니며
[View 컨벤션 — 프리뷰](../view/preview.md)에 따라 독립 파일에 둡니다.
