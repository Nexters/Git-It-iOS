# Git It iOS View 컨벤션

**상태**: 초안

**작성일**: 2026-08-17

**최종 수정일**: 2026-08-18 (5차)

이 문서는 UI 패키지의 재사용 컴포넌트와 Feature 패키지의 화면이 **공통으로** 지켜야
하는 구현 컨벤션을 정의합니다. 두 패키지에 걸쳐 있어 한쪽 패키지 규칙 문서에만 두면
표현이 갈라지는 항목 — 공개 생성 경로, 디자인 토큰 사용, View 내부 선언, 화면 조립,
접근성, 프리뷰 — 을 이 문서가 단독으로 소유합니다.

패키지 책임과 의존 방향은 [아키텍처 문서](./architecture.md), 공개 이름은
[네이밍 가이드](./naming.md), 각 패키지의 소유 범위와 제약조건은
[UI 패키지 규칙](./package-rules/ui.md) · [Feature 패키지 규칙](./package-rules/feature.md)을
정본으로 따릅니다. 이 문서가 Constitution 또는 아키텍처 문서와 충돌하면 상위 문서를
따르고 이 문서를 수정합니다.

## 1. 적용 범위

다음 선언에 적용합니다.

- `sources/Projects/UI/UIComponent/Components/**`의 모든 컴포넌트
- `sources/Projects/UI/DesignSystem/**`의 토큰과 토큰 적용 API
- `sources/Projects/Feature/Presentation/**`의 모든 화면과 화면 보조 선언

다음은 이 문서가 다루지 않습니다.

- 컴포넌트를 **분리할지 말지**의 판단 — [UI 패키지 규칙](./package-rules/ui.md#재사용-판단)
- 말단·조합 컴포넌트의 **분류 기준** — [UI 패키지 규칙](./package-rules/ui.md#말단-컴포넌트)
- 공개 **이름**의 어휘 선택 — [네이밍 가이드](./naming.md)
- `// MARK:` 구획, 선언 순서, 들여쓰기 — Swift Style의 `organizeDeclarations`가
  빌드 시 자동 적용하므로 사람이 관리하지 않습니다.

## 2. 표현 계층

표현은 세 계층으로 나뉘며 각 계층은 아래 계층만 사용합니다.

| 계층 | 소유 | 소유하지 않는 것 |
|---|---|---|
| DesignSystem | 원시 토큰, 의미 토큰, 토큰 적용 modifier | 컴포넌트, 화면 |
| UIComponent | 화면에서 독립된 말단·조합 컴포넌트 | 화면 흐름, Feature 타입 |
| Feature 화면 | 화면 조립, 상태 분기, 화면 흐름 | 재사용 컴포넌트, 시각 어휘 정의 |

**시각 어휘는 DesignSystem이 단독으로 소유합니다.** Feature나 UIComponent가
`extension Color`, `extension Font`처럼 플랫폼 타입에 자신만의 시각 어휘를 추가해
두 번째 토큰 계층을 만들지 않습니다(§4.1).

### 2.1 검토·디버그 전용 컴포넌트

TestFlight 레이아웃 검토 도구처럼 제품 화면이 아닌 UI는 제품 컴포넌트와 같은
디렉터리에 두지 않고 `Components/Review/`에 둡니다. 이 컴포넌트는 다음 예외를
가집니다.

- 제품 시각 어휘 대신 플랫폼 기본 표현(`List`, `.ultraThinMaterial`)을 쓸 수 있습니다.
- 디자인 토큰 적용 의무(§4)와 접근성 조합 규칙(§7.2)의 대상이 아닙니다.

그 외 규칙 — 파일 구성, 공개 생성 경로, View 내부 선언 — 은 동일하게 적용합니다.
제품 컴포넌트는 검토 전용 컴포넌트를 참조하지 않습니다.

## 3. 공개 생성 경로

### 3.1 ViewModel과 콜백

컴포넌트와 화면은 표시할 정보와 표현 상태를 불변 `ViewModel`로 받고, 사용자 입력은
초기화 인자로 받은 콜백으로 상위에 전달합니다. `ViewModel`에 콜백을 넣지 않습니다.
세부 규칙은 [UI 패키지 규칙](./package-rules/ui.md#파일과-선언-구성)을 따릅니다.

`ViewModel`의 모든 프로퍼티에 기본값이 있으면 초기화 메서드에서
`viewModel: ViewModel = .init()`으로 기본값을 제공합니다. 호출부가 기본 표현을 쓸 때
빈 `ViewModel`을 명시적으로 구성하지 않게 하기 위한 것입니다.

### 3.2 컴포넌트의 공개 생성 경로는 두 가지입니다

컴포넌트가 공개하는 생성 경로는 다음 둘뿐입니다.

1. `init(viewModel:)` — 콜백과 `@ViewBuilder` 자식이 있으면 함께 받습니다.
2. 시각 변형별 `public static func` 팩토리 — 고정된 토큰 조합에 이름을 부여합니다.

**토큰과 표현 값을 호출부가 직접 나열하는 편의 init을 정의하지 않습니다.**
`ActionButton(title:style:isEnabled:)`처럼 `ViewModel`의 프로퍼티를 그대로 펼친
초기화 메서드는 `ViewModel` 계약을 우회하는 두 번째 공개 표면을 만들고, 팩토리가
표현하려던 시각 의미를 호출부의 토큰 나열로 되돌립니다.

```swift
// 정본
ActionButton.primary("계속하기") { store.send(.continueTapped) }
StyledText.body2(project.technologies, color: .grey400)
TagBadge.accent("문제 풀기")

// 사용하지 않습니다
ActionButton(title: "계속하기", style: .primary)
StyledText(text: project.technologies, style: .body2, color: .grey400)
TagBadge(text: "문제 풀기", color: .blue100)
```

팩토리는 `Self`를 반환하고 내부에서 `ViewModel`을 구성하며, 호출부는 텍스트, 상태와
콜백처럼 화면 문맥에 따라 달라지는 값만 전달합니다. 팩토리 이름은 특정 Feature의 업무
역할이 아니라 `neutral`, `accent`, `destructive`처럼 UI 패키지에서 독립적으로 해석할
수 있는 시각 의미를 사용하고, Typography 팩토리는 적용하는 `TextStyleToken` 이름과
일치시킵니다.

### 3.3 팩토리를 정의하는 기준

고정된 토큰 조합을 갖는 **시각 변형이 둘 이상일 때만** 팩토리를 정의합니다. 변형이
하나뿐인 컴포넌트는 `init(viewModel:)`만 공개하고 `standard` 같은 무의미한 이름의
팩토리를 만들지 않습니다.

`@ViewBuilder`로 자식 View를 받는 조합 컴포넌트는 팩토리 대신
`init(viewModel:content:)`를 기본 생성 경로로 두고, 필요한 기본값은 §3.1에 따라
`ViewModel`에 둡니다.

변형을 구분하는 `Style` 열거형은 `ViewModel`의 프로퍼티 타입으로 계속 존재하지만
호출부의 기본 선택 수단은 아닙니다. 호출부는 팩토리를 쓰고, `Style` 값은 `ViewModel`을
직접 구성하는 경우에만 지정합니다. `Style`의 선언 위치와 책임은 §5.2를 따릅니다.

### 3.4 화면의 생성 경로

Feature 화면은 컴포넌트와 달리 시각 변형이 아니라 **화면 상태**를 입력받으므로
팩토리와 `Style`을 정의하지 않고 `init(viewModel:)`만 공개합니다.

화면이 표현 상태를 가지면 `ViewModel`을 정의하고, 상태가 없으면 정의하지 않습니다.
화면 `ViewModel`은 컴포넌트와 같이 화면 타입에 중첩해 화면 파일에 둡니다(§5).

```swift
// Screens/Home/HomeView.swift
public struct HomeView: View {
    public init(viewModel: ViewModel = .init()) {
        self.viewModel = viewModel
    }

    public struct ViewModel: Sendable, Equatable {
        public init(hasProjects: Bool = true) {
            self.hasProjects = hasProjects
        }

        public let hasProjects: Bool
    }

    public var body: some View {
        ScreenContainer {
            if viewModel.hasProjects {
                projectList
            } else {
                emptyState
            }
        }
    }

    private let viewModel: ViewModel
}
```

여러 화면이 함께 쓰는 보조 타입은 어느 한 화면이 소유하지 않으므로 중첩하지 않고
`Presentation/Shared/`의 독립 파일에 최상위 타입으로 둡니다. 한 화면만 쓰는 보조
타입은 §5에 따라 그 화면에 중첩합니다.

### 3.5 접근 수준

- UIComponent의 컴포넌트: `public`
- 프리뷰 전용 타입: `internal`
- Feature 화면: App이 목적지로 생성하는 화면만 `public`, 다른 화면 안에서만
  생성되는 화면은 `internal`
- View에 중첩한 `ViewModel`, `Style`과 그 밖의 보조 타입: 소유 View와 같은 접근 수준
- View에 중첩한 `Constant`: 항상 `private`

"모든 화면을 `public`으로 연다"와 "필요할 때 연다"를 파일마다 다르게 적용하지
않습니다. 화면을 `public`으로 여는 근거는 App의 Navigation에서 생성되는지 여부
하나입니다.

중첩 선언은 소유 View의 공개 계약의 일부이므로 View보다 좁거나 넓은 접근 수준을
따로 정하지 않습니다. `public` 컴포넌트의 `ViewModel`과 `Style`은 `public`,
`internal` 화면의 `ViewModel`은 `internal`입니다.

## 4. 디자인 토큰

### 4.1 의미 색상은 DesignSystem이 소유합니다

`ColorToken`은 팔레트 원시 값(`grey600`, `blue100`)을 표현합니다. 화면에서 반복되는
**역할**(카드 배경, 보조 텍스트, 강조)에는 원시 토큰을 직접 쓰지 않고 DesignSystem이
소유하는 `SemanticColorToken`을 사용합니다. `SemanticColorToken`은 역할 이름과 참조하는
`ColorToken`을 함께 소유하며 §4.2의 적용 API가 두 타입을 모두 받습니다.

의미 토큰은 다음 기준을 모두 만족할 때 정의합니다.

1. 이름이 팔레트 위치가 아니라 화면에서의 역할을 설명합니다.
   (`cardBackground` ○ / `purpleSurface` ×, `darkAccent` ×)
2. 역할이 바뀌면 참조하는 원시 토큰이 함께 바뀌어야 합니다.
3. 둘 이상의 컴포넌트 또는 화면이 같은 역할로 사용합니다.

기준을 만족하지 못하는 팔레트 별칭은 정의하지 않고 원시 `ColorToken`을 그대로
사용합니다.

**Feature와 UIComponent는 `extension Color`로 자체 색상 이름을 정의하지 않습니다.**
필요한 의미 이름이 없으면 DesignSystem에 추가하고, 추가할 근거가 없으면 원시 토큰을
사용합니다.

### 4.2 색상 적용 방법

한 파일 안에서 색상 표현 방식을 섞지 않습니다.

- View의 전경·배경: `designSystemForeground(_:)` · `designSystemBackground(_:)`
- 도형 채우기나 `in:` 인자처럼 `Color` 값이 필요한 위치: `Color(designSystem:)`
- `Color(red:green:blue:)`, `Color(hex:)` 등 토큰 밖 색상 리터럴: 사용하지 않습니다.

세 API 모두 `ColorToken`과 `SemanticColorToken` 오버로드를 제공하므로 역할이 있는
색은 의미 토큰을, 변형별 팔레트 선택은 원시 토큰을 같은 호출 형태로 전달합니다.

### 4.3 레이아웃·모서리·컨트롤 크기

여러 컴포넌트나 화면이 공유하는 수치는 컴포넌트마다 복제하지 않고 DesignSystem
토큰으로 승격한 뒤 토큰 적용 API로 사용합니다.

| 값 | 토큰 | 적용 API |
|---|---|---|
| 화면 가로 여백 | `LayoutToken.margin` | `designSystemScreenMargin()` |
| 요소 간 기본 간격 | `LayoutToken.gutter` | 직접 참조 |
| 모서리 반경 | `CornerRadiusToken` | `designSystemCornerRadius(_:)` · `RoundedRectangle(designSystem:)` |
| 컨트롤 크기 | `ControlSizeToken` | `designSystemControlHeight(_:)` · `designSystemControlSize(_:)` |

`in:` 인자로 도형을 넘기는 위치에서는 `RoundedRectangle(designSystem:)`을 사용해
`clipShape` 경로와 같은 토큰을 참조합니다.

토큰 적용 API가 존재하는데도 같은 수치를 리터럴로 반복하지 않습니다. 반대로 한
컴포넌트 안에서만 의미를 갖는 수치는 토큰이 아니라 §5의 `Constant`로 둡니다.

`ControlSizeToken`은 `DesignTokenSet.validate()`에서 44pt 미만을 오류로 판정합니다.
44pt 미만의 터치 대상이 필요하면 토큰이 아니라 컴포넌트 로컬 상수로 두고, 실제 터치
영역은 `contentShape` 또는 확장된 `frame`으로 44pt 이상을 확보합니다.

### 4.4 Typography

문자열 렌더링은 `Text`를 직접 구성하지 않고 `StyledText`의 Typography 팩토리를
사용합니다. `TextStyleToken`은 자간·행간·언어별 폰트 선택을 함께 결정하므로
`.font(.caption2)` 같은 플랫폼 API로 대체하면 표현이 갈라집니다.

**말단 컴포넌트 예외**: `StyledText`를 렌더링하면 다른 프로젝트 컴포넌트를 포함하게
되어 말단 자격([UI 패키지 규칙](./package-rules/ui.md#말단-컴포넌트))을 잃습니다.
`ActionButton`, `TagBadge`처럼 자기 문자열을 직접 그리는 말단 컴포넌트는
DesignSystem의 토큰 적용 API인 `Text.designSystemStyled(_:style:)`과
`designSystemLineSpacing(_:)`을 사용합니다. 이 경로도 `TextStyleToken`을 통과하므로
표현이 갈라지지 않습니다.

플랫폼 기본 폰트는 SF Symbol의 크기 지정(`.font(.system(size:weight:))`, `.font(.caption)`)과
`TextEditor`처럼 `Text`가 아닌 입력 컨트롤에만 사용합니다.

## 5. View 내부 선언

**View가 소유하는 선언은 별도 파일로 나누지 않고 View 타입 안에 중첩해 View 파일에
함께 둡니다.** 이 규칙은 UIComponent 컴포넌트와 Feature 화면에 동일하게 적용합니다.

| 선언 | 정의하는 경우 | 접근 수준 |
|---|---|---|
| `enum Constant` | View 내부에서만 의미를 갖는 상수값이 있을 때 | 항상 `private` |
| `enum Style` | 시각 변형이 존재할 때 | 소유 View와 동일 |
| `struct ViewModel` | 표시 정보나 표현 상태가 존재할 때 | 소유 View와 동일 |

`Item`, `Control`처럼 View가 소유하는 그 밖의 보조 타입도 같은 규칙으로 중첩합니다.
소유 View가 이름에 문맥을 제공하므로 타입 이름에 View 이름을 반복하지 않습니다.
`ActionButtonStyle`이 아니라 `ActionButton.Style`, `SelectionCardListItem`이 아니라
`SelectionCardList.Item`으로 부릅니다.

한 View의 계약을 읽는 데 필요한 선언을 한 파일에 모으기 위한 규칙입니다. `Constant`는
`body`의 수치가 어디서 오는지, `Style`은 변형마다 무엇이 달라지는지, `ViewModel`은
호출부가 무엇을 전달하는지를 설명하며 셋 다 `body`와 함께 읽어야 의미가 드러납니다.

선언 순서와 `// MARK:` 구획은 §1에 따라 Swift Style이 빌드 시 정렬하므로 파일 안의
배치를 사람이 관리하지 않습니다. 프리뷰 전용 타입은 View의 계약이 아니므로 중첩 대상이
아니며 §8에 따라 독립 파일에 둡니다.

### 5.1 `Constant`

상태와 무관한 수치, 정적 문자열, 플레이스홀더는 case 없는 `private enum Constant`의
`static` 멤버로 정의합니다. 비제네릭 View는 `static let` 저장 프로퍼티를 사용합니다.

```swift
private enum Constant {
    static let controlHeight: CGFloat = 54
    static let cornerRadius: CGFloat = 12
    static let disabledOpacity: Double = 0.65
}
```

**그 View 안에서만 참조하는 디자인 토큰 값도 같은 방식으로 정의합니다.** `ColorToken`,
`SemanticColorToken`, `TextStyleToken`처럼 §4의 토큰 카탈로그를 참조하는 값이라도 한
View 안에서만 쓰이면 `body`에 리터럴로 흩어 두지 않고 `Constant`의 `static` 멤버로
모읍니다. `body`를 읽을 때 그 값이 어떤 역할인지 이름으로 드러내고, 여러 곳에 흩어진
같은 토큰 참조가 나중에 따로 바뀌는 것을 막기 위한 것입니다.

```swift
private enum Constant {
    static let borderColor: ColorToken = .blue200
    static let titleStyle: TextStyleToken = .subtitle3
}
```

여러 View 또는 화면이 같은 토큰 참조를 공유하게 되면 `Constant`에 복제하지 않고
§4.3의 기준에 따라 DesignSystem의 의미 토큰으로 승격합니다. `Constant`는 그 View
하나에서만 의미를 갖는 참조만 소유합니다.

**제네릭 View는 `static var` 연산 프로퍼티로 정의합니다.** Swift는 제네릭 타입에
`static` 저장 프로퍼티를 허용하지 않으므로 `SheetSurface<Content>`처럼 제네릭
파라미터를 갖는 View에서는 `static let`이 컴파일되지 않습니다. 이때 `Constant`를 파일
최상위로 꺼내지 않고 리터럴을 반환하는 `static var`로 형태만 바꿔 View 안에 둡니다.

```swift
public struct SheetSurface<Content: View>: View {
    private enum Constant {
        static var grabberWidth: CGFloat { 48 }
        static var grabberHeight: CGFloat { 4 }
    }
}
```

- `Constant`는 case와 인스턴스 멤버를 소유하지 않습니다.
- `static var`는 제네릭 제약을 피하기 위한 형태이므로 리터럴만 반환하고 값을 계산하지
  않습니다. 계산이 필요한 순간 그 값은 상수가 아닙니다.
- `ViewModel`에 따라 달라지는 값은 상수가 아니므로 `Constant`가 아니라 View의 private
  연산 프로퍼티로 표현합니다.
- 여러 타입이 공유하는 값은 `Constant`에 복제하지 않고 §4.3에 따라 토큰으로 승격합니다.

다음은 상수로 승격하지 않습니다.

- `0`, `1`, `.infinity`처럼 값 자체가 의미인 레이아웃 값
- `lineLimit`, `ForEach` 범위처럼 이름이 설명을 더하지 않는 값

그 외에 **한 파일에서 두 번 이상 나타나거나, 이름 없이는 의미가 드러나지 않는
수치**는 `Constant`에 둡니다.

### 5.2 `Style`

고정된 토큰 조합을 갖는 시각 변형이 **둘 이상일 때만** `Style`을 정의합니다. 변형이
하나뿐인 View는 `Style`을 정의하지 않으며, 화면은 시각 변형이 아니라 화면 상태를
입력받으므로 `Style`을 갖지 않습니다(§3.4).

변형에 따라 갈리는 표현 값은 View의 연산 프로퍼티에서 `switch`로 분기하지 않고 `Style`이
소유합니다. View는 `viewModel.style.titleColor(isEnabled:)`처럼 결과만 읽습니다. 변형이
늘어날 때 고쳐야 할 위치를 열거형 한 곳으로 모으기 위한 것입니다.

```swift
// Components/Leaf/ActionButton.swift
public struct ActionButton: View {
    public init(viewModel: ViewModel, action: @escaping () -> Void) {
        self.viewModel = viewModel
        self.action = action
    }

    public enum Style {
        case primary
        case neutral
        case destructive

        func titleColor(isEnabled: Bool) -> ColorToken {
            guard isEnabled else { return .grey400 }

            switch self {
            case .primary, .destructive: return .grey900
            case .neutral: return .grey100
            }
        }
    }

    public struct ViewModel: Sendable, Equatable {
        public init(title: String, style: Style, isEnabled: Bool = true) {
            self.title = title
            self.style = style
            self.isEnabled = isEnabled
        }

        public let title: String
        public let style: Style
        public let isEnabled: Bool
    }

    public var body: some View {
        Button(action: action) {
            Text.designSystemStyled(viewModel.title, style: .body1)
                .designSystemForeground(viewModel.style.titleColor(isEnabled: viewModel.isEnabled))
                .frame(height: Constant.controlHeight)
        }
        .disabled(!viewModel.isEnabled)
    }

    private let viewModel: ViewModel
    private let action: () -> Void

    private enum Constant {
        static let controlHeight: CGFloat = 54
    }
}
```

`Style`은 `ViewModel`의 프로퍼티 타입이며 호출부의 기본 선택 수단이 아닙니다. 호출부는
§3.2의 시각 변형 팩토리를 사용합니다.

### 5.3 `ViewModel`

View가 표시할 정보나 표현 상태를 가질 때만 정의하고, 없으면 정의하지 않습니다. 콜백을
포함하지 않는다는 계약 규칙은 §3.1을, 화면 `ViewModel`의 예시는 §3.4를 따릅니다.

### 5.4 중첩할 수 없는 경우

Swift 제약으로 중첩이 불가능하거나 중첩이 호출부를 해치는 경우가 있습니다.

- 프로토콜은 타입에 중첩할 수 없습니다.
- 제네릭 타입에 중첩한 타입은 제네릭 인자마다 다른 타입이 되어 호출부가
  `TabShell<A, B>.Item`처럼 인자를 적어야 합니다.

해당하는 선언만 같은 파일의 최상위에 두고 이름에 소유 View를 남깁니다(`TabShellItem`).
이때도 나머지 규칙 — 변형 값의 소유 위치, 접근 수준 — 은 동일하게 지킵니다. 예외는
중첩할 수 없는 선언 하나에만 적용하며 같은 View의 다른 선언까지 최상위로 꺼내지
않습니다.

**제네릭 View의 `Constant`는 이 예외가 아닙니다.** `static` 저장 프로퍼티 제약은
§5.1에 따라 `static var` 연산 프로퍼티로 해소하므로 `Constant`는 제네릭 View에서도
중첩합니다.

반대로 보조 타입을 중첩하려고 View를 제네릭으로 두지 않는 선택도 가능합니다.
`ScreenHeader`는 아바타 슬롯을 `AnyView`로 지워 비제네릭을 유지합니다.

## 6. 화면 조립

### 6.1 화면 골격

화면은 다음 컴포넌트로 골격을 구성하고 같은 책임을 화면에서 다시 구현하지 않습니다.

| 책임 | 컴포넌트 |
|---|---|
| 화면 배경·색 구성표·전체 영역 | `ScreenContainer` |
| 상단 제목과 좌우 컨트롤 | `ScreenHeader` |
| 하단 고정 액션 영역 | `BottomActionBar` |
| 시트 표면 | `SheetSurface` |
| 탭 구조 | `TabShell` |

**색 구성표는 `ScreenContainer`가 단독으로 소유합니다.** 화면에서
`preferredColorScheme(_:)`를 다시 지정하지 않습니다. `ScreenContainer` 밖에 오버레이를
쌓아야 해서 색 구성표가 적용되지 않는 경우에는 오버레이를 `ScreenContainer` 안으로
옮기고, 구조상 불가능하면 그 이유를 코드 주석이 아니라 이 문서의 예외로 기록합니다.

### 6.2 화면이 소유하는 것과 소유하지 않는 것

- 화면은 상태 분기, 화면 목적지 생성, 컴포넌트 조립을 소유합니다.
- 화면에서 독립적으로 이름 붙일 수 있는 표현 책임은 UIComponent로 옮깁니다.
- 화면 전용 렌더링 조각은 별도 `View` 타입으로 추출하지 않고 화면의 private 연산
  프로퍼티 또는 메서드로 유지합니다.

세부 기준은 [Feature 패키지 규칙](./package-rules/feature.md)을 따릅니다.

### 6.3 표시용 표본 데이터

레이아웃 검토 단계의 화면이 참조하는 표본 데이터는 화면 파일에 하드코딩하지 않고
`Presentation/Shared/Models/`의 `internal` 표본 타입에 모읍니다. 표본 타입은 컴포넌트
`ViewModel`이 아니며 UI 패키지로 넘기지 않습니다.

화면이 실제 상태에 연결될 때 표본 참조는 화면 `ViewModel`의 프로퍼티로 대체하고,
표본 타입은 해당 화면의 참조가 모두 사라진 시점에 제거합니다.

## 7. 접근성

### 7.1 컴포넌트가 접근성 의미를 소유합니다

접근성 라벨과 trait는 컴포넌트가 소유하고 화면에서 다시 지정하지 않습니다. 화면이
라벨을 덮어써야 한다면 그 값은 표현 상태이므로 컴포넌트 `ViewModel`의 프로퍼티여야
합니다.

### 7.2 규칙

- 심볼만 표시하는 컨트롤은 SF Symbol 이름을 라벨로 사용하지 않습니다. 의미 라벨을
  `ViewModel`의 필수 값으로 소유합니다. 심볼 이름은 렌더링 정보이지 사용자가 인지하는
  이름이 아닙니다.
- 여러 요소가 하나의 의미 단위인 카드·행 컴포넌트는
  `accessibilityElement(children: .combine)`으로 묶습니다.
- 선택 상태는 색이나 테두리만으로 표현하지 않고 `.isSelected` trait를 함께 부여합니다.
- 묶인 요소 안에 독립 동작 버튼이 있으면 버튼에 별도 라벨을 부여해 조합에서
  분리합니다.

## 8. 프리뷰

| 대상 | 위치 | 이름 |
|---|---|---|
| UIComponent | 컴포넌트 파일 하단 `#Preview` | 컴포넌트 이름 |
| Feature 화면 | `Screens/Previews/<영역>Previews.swift` | 화면과 상태를 설명하는 한국어 이름 |

- 컴포넌트 프리뷰는 모든 시각 변형을 한 프리뷰에 나열해 변형 간 차이를 함께 봅니다.
- 컴포넌트 프리뷰의 배경은 `designSystemBackground(.grey700)`으로 실제 화면 배경 위의
  대비를 확인합니다.
- 화면 프리뷰는 `catalogPreviewFrame()`으로 동일한 검토 프레임을 사용합니다.
- 화면 파일 안에 `#Preview`를 두지 않습니다. 화면 프리뷰는 상태 조합마다 늘어나므로
  화면 구현과 분리해 목록으로 관리합니다.
- 프리뷰 전용 타입은 프리뷰가 필요한 컴포넌트 파일이 아니라 독립 파일에 둡니다.

## 9. 검토 체크리스트

### 공개 계약

- [ ] 공개 생성 경로가 `init(viewModel:)`과 시각 변형 팩토리뿐인가?
- [ ] `ViewModel` 프로퍼티를 그대로 펼친 편의 init이 없는가?
- [ ] 팩토리 이름이 Feature 업무 역할이 아니라 시각 의미를 표현하는가?
- [ ] 콜백이 `ViewModel`이 아니라 초기화 인자인가?
- [ ] 화면의 `public` 여부가 App Navigation 생성 여부와 일치하는가?

### 토큰

- [ ] 토큰 밖 색상 리터럴이 없는가?
- [ ] `extension Color`로 패키지 로컬 색상 이름을 추가하지 않았는가?
- [ ] 여러 곳이 공유하는 수치를 토큰으로 승격했는가?
- [ ] 문자열이 `StyledText` Typography 팩토리를 통과하는가?
- [ ] 한 View 안에서만 쓰는 토큰 참조가 `body`에 흩어지지 않고 `Constant`의
      `static` 멤버로 모여 있는가?

### 구조

- [ ] `Constant`, `Style`, `ViewModel`과 보조 타입이 View 타입에 중첩되어 View 파일에
      함께 있는가?
- [ ] 최상위로 꺼낸 선언이 §5.4의 중첩 불가 사유에 해당하는가?
- [ ] 중첩 타입 이름이 소유 View 이름을 반복하지 않는가?
- [ ] 이름 없이 의미가 드러나지 않는 수치가 `Constant`에 있는가?
- [ ] `Constant`에 case와 인스턴스 멤버가 없고 멤버가 리터럴만 반환하는가?
- [ ] 제네릭 View의 `Constant`가 파일 최상위가 아니라 View 안에 `static var`로 있는가?
- [ ] 변형별 표현 값을 View가 아니라 `Style`이 소유하는가?
- [ ] 화면 안에 별도 `View` 타입을 정의하지 않았는가?
- [ ] 화면이 `preferredColorScheme`을 다시 지정하지 않는가?
- [ ] 검토 전용 컴포넌트가 제품 컴포넌트 디렉터리 밖에 있는가?

### 접근성과 프리뷰

- [ ] 심볼 전용 컨트롤이 의미 라벨을 소유하는가?
- [ ] 카드·행이 하나의 접근성 요소로 묶이고 선택 상태에 trait가 있는가?
- [ ] 컴포넌트 프리뷰가 모든 시각 변형을 포함하는가?
- [ ] 화면 프리뷰가 `Screens/Previews/`에 있는가?

## 문서 변경 기준

이 문서는 UI 컴포넌트와 Feature 화면에 **공통으로** 적용되는 구현 컨벤션이 바뀔 때
수정합니다. 한 패키지에만 적용되는 규칙은 해당 패키지 규칙 문서에서 관리합니다.
