# UI 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

**최종 수정일**: 2026-08-18

## 설명

UI는 시각 언어와 화면에서 독립된 모든 재사용 UI 구성요소를 담당하는 표현 경계입니다. 디자인 토큰, Typography, Color, Icon과 제품 표현 컴포넌트를 제공하여 Feature가 일관된 화면을 구성할 수 있도록 합니다.

UI의 공개 API는 Feature 구현 타입과 분리된 `ViewModel`과 콜백으로 시각 표현과 사용자 인터랙션을 제공합니다.

이 문서는 UI 패키지가 **무엇을 소유하고 어떻게 분리하는지**를 정의합니다. 컴포넌트와
Feature 화면에 공통으로 적용되는 구현 컨벤션 — 공개 생성 경로, 디자인 토큰 사용,
View 내부 선언, 접근성, 프리뷰 — 은 [View 컨벤션](../view-conventions.md)을 따릅니다.

## 정책

- 공개 이름은 [네이밍 가이드](../naming.md)를 따르며 시각 의미와 재사용 책임을 드러내고 Feature의 State, Action 또는 내부 모델 이름을 공용 API에 노출해서는 안 됩니다.
- 모든 내부 target은 공용 디자인 규칙 또는 재사용 가능한 UI 구성요소를 제공해야 합니다.
- 공개 API는 현재 사용처 수와 관계없이 화면에서 독립된 표현 계약으로 설계해야 합니다.
- 디자인 토큰, Typography, Color, Icon과 범용 또는 제품 고유 UI Component를 소유할 수 있습니다.

## 말단 컴포넌트

### 정의

컴포넌트는 `ViewModel`이 표현하는 의미를 `View`로 렌더링하는 하나의 계약입니다.
말단 컴포넌트는 그 계약의 렌더링 트리에 프로젝트가 소유한 다른 `View` 컴포넌트를
포함하지 않는 최하위 단위입니다.

말단 여부는 화면에서 차지하는 크기나 구현 라인 수가 아니라 의존 구조로 판단합니다.
다음 요소는 말단 컴포넌트 내부에서 사용할 수 있습니다.

- 플랫폼이 제공하는 기본 `View`, `Shape`와 modifier
- DesignSystem이 제공하는 토큰과 토큰 적용 API
- 같은 컴포넌트의 `body`, private 연산 프로퍼티 또는 private 메서드로 분해한
  렌더링 조각

다음 조건 중 하나라도 해당하면 말단 컴포넌트가 아닙니다.

- 프로젝트가 소유한 다른 컴포넌트 타입을 생성해 렌더링합니다.
- 제네릭 `Content` 또는 `ViewBuilder`를 통해 임의의 자식 `View`를 입력받습니다.
- 같은 파일의 별도 `View` 타입에 렌더링 책임을 위임합니다.

이러한 타입은 조합 컴포넌트나 화면으로 분류하고, 말단 컴포넌트와 섞어 호칭하지
않습니다.

### 재사용 판단

재사용 가능성은 사용처의 수나 외형의 유사성이 아니라 `ViewModel`의 의미적 통일성으로
판단합니다. 다른 화면이나 상태에서도 다음 질문에 모두 같은 답을 할 수 있어야
하나의 컴포넌트를 재사용합니다.

1. `ViewModel`의 각 프로퍼티는 같은 사용자 인지 역할을 표현하는가?
2. 같은 상태 값은 모든 사용처에서 같은 상태와 표현 규칙을 의미하는가?
3. nil, 빈 값, 범위 밖 값과 같은 경계값을 같은 방식으로 해석하는가?
4. VoiceOver 라벨과 trait를 포함한 접근성 의미가 같은가?
5. 특정 Feature의 모델을 다른 의미로 치환하거나 범용적인 이름 뒤에 숨기지 않는가?

둥글고 색이 같다는 이유만으로 서로 다른 의미의 상태를 하나의 `isActive`로 통합하지
않습니다. 반대로 화면 문맥이 달라도 모든 프로퍼티와 상태의 의미가 같다면
같은 `ViewModel` 계약을 사용할 수 있습니다. 현재 사용처가 하나라는 사실만으로 재사용
가능성을 인정하거나 부정하지 않습니다.

UI 패키지는 범용 시각 요소뿐 아니라 제품 고유의 표현 의미를 가진 컴포넌트도
소유합니다. 다만 공개 `ViewModel`은 Feature의 State, Action 또는 업무 모델을 직접
참조하지 않고 렌더링에 필요한 불변 값만 소유해야 합니다. Feature는 경계에서 자신의
모델을 이 값으로 변환하며 사용자 입력은 별도 콜백으로 전달합니다.

### 파일과 선언 구성

`UIComponent`의 말단 컴포넌트는 `Components/Leaf/`, 다른 프로젝트 컴포넌트나
임의의 자식 View를 포함하는 조합 컴포넌트는 `Components/Composite/`에 둡니다.
제품 화면이 아닌 검토·디버그 전용 컴포넌트는 두 폴더가 아니라 `Components/Review/`에
두며 예외 범위는 [View 컨벤션 §2.1](../view-conventions.md#21-검토디버그-전용-컴포넌트)을
따릅니다.

세 폴더 아래에는 컴포넌트마다 폴더를 만들지 않고 컴포넌트 파일을 바로 둡니다
(`Components/Leaf/ActionButton.swift`). 컴포넌트가 소유하는 선언은 컴포넌트 파일 안에
중첩하므로 대부분의 컴포넌트는 파일 하나로 끝나고, 폴더를 두면 파일 하나만 담은 폴더가
됩니다.

프리뷰 전용 타입이나 중첩할 수 없는 보조 타입처럼 컴포넌트에 딸린 파일이 필요하면
같은 폴더에 소유 컴포넌트 이름을 앞에 붙인 파일로 나란히 둡니다.
`Components/Composite/`는 `TabShell.swift`와 제네릭 제약으로 중첩할 수 없는
`TabShellItem.swift`를 나란히 소유합니다. 딸린 파일이 있다는 이유로 그 컴포넌트에만
폴더를 만들지 않습니다.

컴포넌트 파일과 타입 이름은 컴포넌트가 표현하는 대상으로 짓고 `View` 접미어를 붙이지
않습니다. `View` 준수는 선언이 이미 제공하는 문맥이라
[네이밍 가이드 §2.2](../naming.md#22-필요한-최소-문맥을-남깁니다)의 중복 수식어에
해당합니다.

모든 Swift 파일은 최상위 `struct`, `enum`, `class`, `actor` 또는 `protocol`
타입을 정확히 하나만 정의하며 파일 이름은 그 최상위 타입 이름과 일치해야 합니다.
[View 컨벤션 §5.4](../view-conventions.md#54-중첩할-수-없는-경우)의 중첩 불가 선언만
이 규칙의 예외입니다.

컴포넌트가 소유하는 선언 — `ViewModel`, `Style`, `Constant`와 `Item`, `Control` 같은
보조 타입 — 은 예외 없이 컴포넌트 `View` 내부에 중첩하고 컴포넌트 파일에 함께 둡니다.
보조 타입을 `<컴포넌트>+<역할>.swift` 같은 별도 파일로 나누지 않습니다. 배치 규칙과
중첩 예외는 [View 컨벤션 §5](../view-conventions.md#5-view-내부-선언)를 따릅니다.

소유 컴포넌트가 이름에 문맥을 제공하므로 타입 이름에 컴포넌트 이름을 반복하지
않습니다. `ActionButtonStyle`이 아니라 `ActionButton.Style`,
`SelectionCardListItem`이 아니라 `SelectionCardList.Item`으로 부릅니다.

변형에 따라 갈리는 표현 값은 컴포넌트의 연산 프로퍼티에서 `switch`로 분기하지 않고
`Style`이 소유합니다. 컴포넌트는 `viewModel.style.titleColor(isEnabled:)`처럼
결과만 읽습니다.

상위 소유자에게 입력을 전달하는 콜백은 컴포넌트 초기화 인자로 받고 private 저장
프로퍼티로 보존합니다. 저장 상태가 없고 독립적인 재사용 계약을 만들지 않는 렌더링
조각은 컴포넌트의 private 연산 프로퍼티나 메서드로 유지할 수 있습니다.

`ViewModel`은 컴포넌트가 표시하는 정보와 표현 상태를 불변 값으로 소유합니다.
사용자 입력을 상위 소유자에게 전달하는 콜백은 표현 상태가 아니므로 `ViewModel`에
포함하지 않고 컴포넌트 초기화 메서드의 별도 인자로 받습니다.

컴포넌트가 공개하는 생성 경로는 `init(viewModel:)`과 시각 변형별
`public static func` 팩토리뿐이며 `ViewModel` 프로퍼티를 펼친 편의 init을 정의하지
않습니다. 팩토리를 정의하는 기준과 이름 규칙은
[View 컨벤션 §3](../view-conventions.md#3-공개-생성-경로)을 따릅니다.

컴포넌트 로컬 상수는 컴포넌트에 중첩된 `private enum Constant` 네임스페이스 안에
`static let` 저장 프로퍼티로만 정의합니다. 승격 기준은
[View 컨벤션 §5.1](../view-conventions.md#51-constant), 제네릭 컴포넌트처럼 중첩할 수
없는 경우는 [§5.4](../view-conventions.md#54-중첩할-수-없는-경우)를 따릅니다.

```swift
public struct TagBadge: View {
    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public struct ViewModel: Sendable, Equatable {
        public init(text: String, color: ColorToken) {
            self.text = text
            self.color = color
        }

        public let text: String
        public let color: ColorToken
    }

    public var body: some View {
        Text.designSystemStyled(viewModel.text, style: .body2)
            .designSystemLineSpacing(.body2)
            .designSystemForeground(.blue100)
            .padding(.horizontal, Constant.horizontalPadding)
            .padding(.top, Constant.topPadding)
            .padding(.bottom, Constant.bottomPadding)
            .background(Color(designSystem: viewModel.color))
    }

    private let viewModel: ViewModel

    private enum Constant {
        static let horizontalPadding: CGFloat = 10
        static let topPadding: CGFloat = 3
        static let bottomPadding: CGFloat = 4
    }
}
```

### 분리 절차

1. 기존 화면과 사용처에서 독립적으로 이름 붙일 수 있는 표현 책임을 찾습니다.
2. 후보들의 외형이 아니라 모델 필드, 상태, 경계값과 접근성 의미를 비교합니다.
3. 의미가 모두 일치할 때만 하나의 `ViewModel` 계약을 정의합니다.
4. Feature의 State, Action 또는 업무 모델 없이 불변 표현 값과 콜백만으로 계약을
   정의합니다.
5. 다른 프로젝트 UI 컴포넌트를 렌더링하지 않는 후보만 말단 컴포넌트로 분류합니다.
6. `ViewModel`, `Style`, `Constant`와 그 밖의 보조 타입을 모두 컴포넌트 내부에
   중첩해 컴포넌트 파일 하나에 둡니다.
7. 분리 전후의 표시 상태, 사용자 입력 전달과 접근성 의미가 보존되는지 검증합니다.

## 제약조건

- 프로젝트 내부의 다른 패키지에 의존해서는 안 됩니다.
- 특정 Feature의 화면, Action, 상태 또는 화면 흐름을 소유해서는 안 됩니다.
- Feature 패키지의 타입을 컴포넌트 `ViewModel` 또는 초기화 인자로 받아서는 안 됩니다.
- Domain 모델이나 비즈니스 규칙을 참조해서는 안 됩니다.
- Data DTO, 서버 API 또는 데이터 접근 구현을 참조해서는 안 됩니다.
- 네트워크, 저장소 또는 Composition 로직을 구현해서는 안 됩니다.
- 외형만 같고 `ViewModel`의 의미가 다른 UI를 하나의 컴포넌트로 통합해서는 안 됩니다.
- Feature 모델을 범용 이름으로 감싼 공용 `ViewModel`인 것처럼 노출해서는 안 됩니다.
- `UIComponent`에서 `extension Color`처럼 DesignSystem 밖에 시각 어휘를 정의해서는 안
  됩니다.
- 제품 컴포넌트가 검토·디버그 전용 컴포넌트를 참조해서는 안 됩니다.
