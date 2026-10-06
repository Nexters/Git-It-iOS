# Git It iOS View 내부 선언 컨벤션

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-08-31 ([View 컨벤션](./view.md)에서 분리)

## 목적

이 문서는 UIComponent 컴포넌트와 Feature 화면이 소유하는 비상태 보조 선언
(`Constant`, `Style`, 그 밖의 보조 타입)을 View 파일에 중첩하는 방식과, Swift 제약으로
중첩할 수 없는 경우의 예외를 정의합니다. 공개 생성 경로, 화면 조립과 프리뷰는
[View 컨벤션](./view.md), 디자인 토큰 사용 규칙은
[View 토큰 컨벤션](./view-tokens.md)이 소유합니다.

상위 문서와의 우선순위는 [컨벤션 공통 규칙](./README.md#상위-문서와-충돌-해소)을
따릅니다.

## 1. 적용 범위

- `sources/Projects/UI/Component/**` 컴포넌트가 소유하는 `Constant`, `Style`과 그 밖의
  비상태 보조 타입
- `sources/Projects/Feature/**` 화면이 소유하는 `Constant`와 화면 전용 렌더링 보조 선언

Feature의 `State`, `Action`, Reducer와 cancellation ID는 View가 아니라 Feature 타입이
소유하므로 이 문서의 적용 대상이 아닙니다([TCA 컨벤션](./tca/README.md)).

## 2. View 내부 선언

**View가 소유하는 선언은 별도 파일로 나누지 않고 View 타입 안에 중첩해 View 파일에
함께 둡니다.** 이 규칙은 UIComponent 컴포넌트와 Feature 화면에 동일하게 적용합니다.
단, Feature의 `State`, `Action`, Reducer와 cancellation ID는 View가 아니라 Feature 타입이
소유하므로 화면 파일로 옮기지 않습니다.

| 선언 | 정의하는 경우 | 접근 수준 |
|---|---|---|
| `enum Constant` | View 내부에서만 의미를 갖는 상수값이 있을 때 | 항상 `private` |
| `enum Style` | UI 컴포넌트에 시각 변형이 존재할 때 | 필요한 최소 수준 |

`Item`, `Control`처럼 View가 소유하는 그 밖의 보조 타입도 같은 규칙으로 중첩합니다.
Feature 화면에는 `Constant`와 화면 전용 렌더링 보조 선언만 둘 수 있으며, 상태·Action을
다시 표현하는 보조 모델은 만들지 않습니다([View 컨벤션 §3.1](./view.md#31-표시-값-binding과-콜백)).
소유 View가 이름에 문맥을 제공하므로 타입 이름에 View 이름을 반복하지 않습니다.
`ActionButtonStyle`이 아니라 `ActionButton.Style`, `SelectionCardListItem`이 아니라
`SelectionCardList.Item`으로 부릅니다.

한 View의 렌더링 규칙을 읽는 데 필요한 비상태 선언을 한 파일에 모으기 위한 규칙입니다.
`Constant`는 `body`의 수치가 어디서 오는지, `Style`은 변형마다 무엇이 달라지는지를
설명합니다. 표시 값과 `Binding`은 별도 타입으로 감싸지 않고 컴포넌트 저장 프로퍼티에
직접 둡니다.

선언 순서와 `// MARK:` 구획은 [View 컨벤션 §1](./view.md#1-적용-범위)에 따라 Swift
Style이 빌드 시 정렬하므로 파일 안의 배치를 사람이 관리하지 않습니다. 프리뷰 전용
타입은 View의 계약이 아니므로 중첩 대상이 아니며
[View 컨벤션 §5](./view.md#5-프리뷰)에 따라 독립 파일에 둡니다.

### 2.1 `Constant`

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
`SemanticColorToken`, `TextStyleToken`처럼
[View 토큰 컨벤션 §2](./view-tokens.md#2-디자인-토큰)의 토큰 카탈로그를 참조하는
값이라도 한 View 안에서만 쓰이면 `body`에 리터럴로 흩어 두지 않고 `Constant`의
`static` 멤버로 모읍니다. `body`를 읽을 때 그 값이 어떤 역할인지 이름으로 드러내고,
여러 곳에 흩어진 같은 토큰 참조가 나중에 따로 바뀌는 것을 막기 위한 것입니다.

```swift
private enum Constant {
    static let borderColor: ColorToken = .blue200
    static let titleStyle: TextStyleToken = .subtitle3
}
```

여러 View 또는 화면이 같은 토큰 참조를 공유하게 되면 `Constant`에 복제하지 않고
[View 토큰 컨벤션 §2.3](./view-tokens.md#23-레이아웃모서리컨트롤-크기)의 기준에 따라
DesignSystem의 의미 토큰으로 승격합니다. `Constant`는 그 View 하나에서만 의미를 갖는
참조만 소유합니다.

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
- 외부 입력이나 `Binding` 값에 따라 달라지는 값은 상수가 아니므로 `Constant`가 아니라
  View의 private 연산 프로퍼티로 표현합니다.
- 여러 타입이 공유하는 값은 `Constant`에 복제하지 않고
  [View 토큰 컨벤션 §2.3](./view-tokens.md#23-레이아웃모서리컨트롤-크기)에 따라
  토큰으로 승격합니다.

다음은 상수로 승격하지 않습니다.

- `0`, `1`, `.infinity`처럼 값 자체가 의미인 레이아웃 값
- `lineLimit`, `ForEach` 범위처럼 이름이 설명을 더하지 않는 값

그 외에 **한 파일에서 두 번 이상 나타나거나, 이름 없이는 의미가 드러나지 않는
수치**는 `Constant`에 둡니다.

### 2.2 `Style`

고정된 토큰 조합을 갖는 시각 변형이 **둘 이상일 때만** `Style`을 정의합니다. 변형이
하나뿐인 View는 `Style`을 정의하지 않으며, 화면은 시각 변형이 아니라 화면 상태를
입력받으므로 `Style`을 갖지 않습니다([View 컨벤션 §3.4](./view.md#34-화면의-생성-경로)).

변형에 따라 갈리는 표현 값은 View의 연산 프로퍼티에서 `switch`로 분기하지 않고 `Style`이
소유합니다. View는 `style.titleColor(isEnabled:)`처럼 결과만 읽습니다. 변형이
늘어날 때 고쳐야 할 위치를 열거형 한 곳으로 모으기 위한 것입니다.

```swift
// Controls/ActionButton.swift
public struct ActionButton: View {
    public init(
        title: String,
        style: Style,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
    ) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
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

    public var body: some View {
        Button(action: action) {
            Text.designSystemStyled(title, style: .body1)
                .designSystemForeground(style.titleColor(isEnabled: isEnabled))
                .frame(height: Constant.controlHeight)
        }
        .disabled(!isEnabled)
    }

    private let title: String
    private let style: Style
    private let isEnabled: Bool
    private let action: () -> Void

    private enum Constant {
        static let controlHeight: CGFloat = 54
    }
}
```

`Style`은 상태 wrapper가 아니며 시각 변형만 소유합니다. 호출부는
[View 컨벤션 §3.2](./view.md#32-컴포넌트의-공개-생성-경로는-두-가지입니다)의 시각
변형 팩토리를 기본 선택 수단으로 사용합니다.

### 2.3 외부 상태와 `Binding`

UI 컴포넌트는 표시 상태의 원본을 소유하지 않습니다. 읽기 전용 값은 불변 저장
프로퍼티로 받고, 컴포넌트의 조작 결과를 외부 상태에 즉시 반영해야 하는 경우에만
SwiftUI `Binding`을 받습니다. 단방향 이벤트는 `Binding`으로 가장하지 않고 콜백으로
전달합니다.

- `@State`, observable reference 또는 별도 상태 wrapper에 외부 값을 복제하지 않습니다.
- `Binding`의 기본값을 `.constant`로 제공해 상태 연결 누락을 숨기지 않습니다.
- 로딩·선택·활성화처럼 외부가 결정하는 상태는 표시 값 또는 `Binding`으로 명시합니다.

### 2.4 중첩할 수 없는 경우

Swift 제약으로 중첩이 불가능하거나 중첩이 호출부를 해치는 경우가 있습니다.

- 프로토콜은 타입에 중첩할 수 없습니다.
- 제네릭 타입에 중첩한 타입은 제네릭 인자마다 다른 타입이 되어 호출부가
  `TabShell<A, B>.Item`처럼 인자를 적어야 합니다.

해당하는 선언만 같은 파일의 최상위에 두고 이름에 소유 View를 남깁니다(`TabShellItem`).
이때도 나머지 규칙 — 변형 값의 소유 위치, 접근 수준 — 은 동일하게 지킵니다. 예외는
중첩할 수 없는 선언 하나에만 적용하며 같은 View의 다른 선언까지 최상위로 꺼내지
않습니다.

**제네릭 View의 `Constant`는 이 예외가 아닙니다.** `static` 저장 프로퍼티 제약은
§2.1에 따라 `static var` 연산 프로퍼티로 해소하므로 `Constant`는 제네릭 View에서도
중첩합니다.

반대로 보조 타입을 중첩하려고 View를 제네릭으로 두지 않는 선택도 가능합니다.
`ScreenHeader`는 아바타 슬롯을 `AnyView`로 지워 비제네릭을 유지합니다.

## 3. 검토 체크리스트

- [ ] UI 컴포넌트의 `Constant`, `Style`과 비상태 보조 타입이 컴포넌트 타입에 중첩되어
      파일에 함께 있는가?
- [ ] Feature 화면에는 `Constant`와 화면 전용 렌더링 보조 선언만 있고, `State`,
      `Action`, Reducer를 중복한 ViewModel·Style이 없는가?
- [ ] 최상위로 꺼낸 선언이 §2.4의 중첩 불가 사유에 해당하는가?
- [ ] 중첩 타입 이름이 소유 View 이름을 반복하지 않는가?
- [ ] 이름 없이 의미가 드러나지 않는 수치가 `Constant`에 있는가?
- [ ] `Constant`에 case와 인스턴스 멤버가 없고 멤버가 리터럴만 반환하는가?
- [ ] 제네릭 View의 `Constant`가 파일 최상위가 아니라 View 안에 `static var`로 있는가?
- [ ] 변형별 표현 값을 View가 아니라 `Style`이 소유하는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [View 컨벤션](./view.md)
- [View 토큰 컨벤션](./view-tokens.md)
- [TCA 컨벤션](./tca/README.md)

## 문서 변경 기준

View 내부 선언의 중첩 규칙, `Constant`·`Style`의 책임 또는 중첩할 수 없는 경우의
예외가 바뀔 때 수정합니다. 공개 생성 경로, 화면 조립이나 프리뷰가 바뀌면 이 문서가
아니라 [View 컨벤션](./view.md)을, 디자인 토큰 사용 규칙이 바뀌면
[View 토큰 컨벤션](./view-tokens.md)을 갱신합니다.
