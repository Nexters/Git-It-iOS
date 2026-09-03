# Git It iOS View 컨벤션

**상태**: 초안

**작성일**: 2026-08-17

**최종 수정일**: 2026-09-03 (화면 전용 서브뷰 규칙 추가, 경계 이름을 `typealias`로 한정)

## 목적

이 문서는 UI 패키지의 재사용 컴포넌트와 Feature 패키지의 화면이 **공통으로** 지켜야
하는 구현 컨벤션 중 공개 생성 경로, 화면 조립과 프리뷰를 정의합니다. 디자인 토큰
사용 규칙은 [View 토큰 컨벤션](./view-tokens.md), View 내부 선언(`Constant`, `Style`
등)은 [View 내부 선언 컨벤션](./view-declarations.md)이 소유합니다. TCA
상태·Effect·의존성 규칙은 [TCA 컨벤션](./tca/README.md)을 따릅니다.

공개 이름은 [네이밍 컨벤션](./naming.md), 각 패키지의 소유 범위와 제약조건은
[UI 패키지 규칙](../package-rules/ui.md) · [Feature 패키지 규칙](../package-rules/feature.md)을
정본으로 따릅니다. 상위 문서와의 우선순위는
[컨벤션 공통 규칙](./README.md#상위-문서와-충돌-해소)을 따릅니다.

## 1. 적용 범위

다음 선언에 적용합니다.

- `sources/Projects/UI/Component/**`의 모든 컴포넌트 공개 생성 경로
- `sources/Projects/Feature/**`의 모든 화면 생성 경로, 화면 조립과 프리뷰

다음은 이 문서가 다루지 않습니다.

- 디자인 토큰 사용 규칙 — [View 토큰 컨벤션](./view-tokens.md)
- View 내부 선언(`Constant`, `Style`, 중첩 규칙) — [View 내부 선언 컨벤션](./view-declarations.md)
- 컴포넌트를 **분리할지 말지**의 판단 — [UIComponent 컨벤션](./ui-component.md#4-재사용-판단)
- 컴포넌트의 **역할 분류 기준** — [UIComponent 컨벤션](./ui-component.md#3-컴포넌트-역할-분류)
- 폴더 뎁스와 파일 분할 — [디렉터리·파일 컨벤션](./directory-file.md)
- 공개 **이름**의 어휘 선택 — [네이밍 컨벤션](./naming.md)
- `// MARK:` 구획, 선언 순서, 들여쓰기 — Swift Style의 `organizeDeclarations`가
  빌드 시 자동 적용하므로 사람이 관리하지 않습니다.

## 2. 표현 계층

표현은 세 계층으로 나뉘며 각 계층은 아래 계층만 사용합니다.

| 계층 | 소유 | 소유하지 않는 것 |
|---|---|---|
| DesignSystem | 원시 토큰, 의미 토큰, 토큰 적용 modifier | 컴포넌트, 화면 |
| UIComponent | 화면에서 독립된 역할별 재사용 컴포넌트 | 화면 흐름, Feature 타입 |
| Feature 화면 | 화면 조립, 상태 분기, 화면 흐름 | 재사용 컴포넌트, 시각 어휘 정의 |

**시각 어휘는 DesignSystem이 단독으로 소유합니다.** Feature나 UIComponent가
`extension Color`, `extension Font`처럼 플랫폼 타입에 자신만의 시각 어휘를 추가해
두 번째 토큰 계층을 만들지 않습니다
([View 토큰 컨벤션 §2.1](./view-tokens.md#21-의미-색상은-designsystem이-소유합니다)).

### 2.1 검토·디버그 전용 컴포넌트

TestFlight 레이아웃 검토 도구처럼 제품 화면이 아닌 UI는 `UIComponent`에 두지 않고
`UIComponentPreviewApp` target이 소유합니다. 이 UI는 다음 예외를 가집니다.

- 제품 시각 어휘 대신 플랫폼 기본 표현(`List`, `.ultraThinMaterial`)을 쓸 수 있습니다.
- 디자인 토큰 적용 의무([View 토큰 컨벤션 §2](./view-tokens.md#2-디자인-토큰))의
  대상이 아닙니다.

그 외 규칙 — 파일 구성, 공개 생성 경로, View 내부 선언 — 은 동일하게 적용합니다.
제품 컴포넌트는 검토 전용 UI를 참조하지 않으며, 검토 전용 UI를 `UIComponent`의 역할
폴더로 옮기지 않습니다.

## 3. 공개 생성 경로

### 3.1 표시 값, Binding과 콜백

UI 컴포넌트는 읽기 전용 표시 값을 초기화 인자로 받고, 외부 소유자가 변경을 관찰해야
하는 값은 SwiftUI `Binding`으로 받습니다. 일회성 사용자 입력은 프레임워크 중립 콜백으로
상위에 전달합니다. 표시 상태를 묶는 `ViewModel`, `State` 또는 동등한 wrapper를 만들지
않으며 TCA `Store`, `Action` 또는 `Effect`를 컴포넌트 계약에 포함하지 않습니다.

초기화 인자에 자연스러운 기본 표현이 있으면 해당 인자에 기본값을 제공합니다. 외부 상태가
필요하지 않은 호출부가 불필요한 `Binding`이나 빈 상태 wrapper를 만들게 하지 않습니다.

### 3.2 컴포넌트의 공개 생성 경로는 두 가지입니다

컴포넌트가 공개하는 생성 경로는 다음 둘뿐입니다.

1. 표시 값·`Binding`·콜백을 직접 받는 `init` — `@ViewBuilder` 자식이 있으면 함께
   받습니다.
2. 시각 변형별 `public static func` 팩토리 — 고정된 토큰 조합에 이름을 부여합니다.

초기화 메서드는 렌더링 계약에 필요한 값만 직접 노출합니다. 여러 인자가 항상 함께
변경된다는 이유만으로 상태 wrapper를 추가하지 않으며, Feature 모델을 그대로 받지도
않습니다. 시각 토큰 묶음은 호출부가 나열하지 않고 `Style` 또는 팩토리가 소유합니다.

```swift
// Feature 호출부의 정본: store는 UI 컴포넌트 내부가 아니라 호출부에만 존재합니다.
ActionButton.primary("계속하기") { store.send(.continueTapped) }
SelectionToggle(isSelected: $store.isSelected)
TagBadge(text: "문제 풀기", color: .blue100)

// 사용하지 않습니다
ProjectRow(project: project)
SelectionToggle(state: .init(isSelected: store.isSelected))
```

팩토리는 `Self`를 반환하고 고정된 시각 변형을 선택하며, 호출부는 텍스트, 상태와
콜백처럼 화면 문맥에 따라 달라지는 값만 전달합니다. 팩토리 이름은 특정 Feature의 업무
역할이 아니라 `neutral`, `accent`, `destructive`처럼 UI 패키지에서 독립적으로 해석할
수 있는 시각 의미를 사용하고, Typography 팩토리는 적용하는 `TextStyleToken` 이름과
일치시킵니다.

### 3.3 팩토리를 정의하는 기준

고정된 토큰 조합을 갖는 **시각 변형이 둘 이상일 때만** 팩토리를 정의합니다. 변형이
하나뿐인 컴포넌트는 직접 초기화 메서드만 공개하고 `standard` 같은 무의미한 이름의
팩토리를 만들지 않습니다.

`@ViewBuilder`로 자식 View를 받는 컴포넌트는 팩토리 대신
`init(..., content:)`를 기본 생성 경로로 두고, 필요한 기본값은 §3.1에 따라 해당
초기화 인자에 둡니다.

변형을 구분하는 `Style` 열거형은 표시 상태 wrapper가 아니라 시각 규칙의
네임스페이스입니다. 호출부의 기본 선택 수단은 팩토리이며, 직접 초기화가 필요한 공개
계약에서만 `Style`을 인자로 받습니다. `Style`의 선언 위치와 책임은
[View 내부 선언 컨벤션 §2.3](./view-declarations.md#23-style)를 따릅니다.

### 3.4 화면의 생성 경로

Feature 화면은 TCA `Store`를 화면 상태의 단일 정본으로 사용하므로
`init(store: StoreOf<Feature>)`를 생성 경로로 둡니다. 화면은 컴포넌트와 달리 별도
`ViewModel`, 시각 변형 팩토리 또는 `Style`을 정의하지 않습니다.

```swift
// Home/HomeView.swift
public struct HomeView: View {
    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        ScreenContainer {
            if store.hasProjects {
                projectList
            } else {
                emptyState
            }
        }
    }

    @Bindable private var store: StoreOf<HomeFeature>
}
```

화면은 `Store`의 상태를 UI 컴포넌트의 표시 값과 SwiftUI `Binding`으로 연결하고
컴포넌트 콜백을 Feature `Action`으로 해석합니다. 여러 화면이 함께 쓰는 View가 아닌
Presentation 보조 타입은
어느 한 화면이 소유하지 않으므로 `Shared/`의 형태 폴더에 최상위 타입으로
둘 수 있습니다. 한 화면만 쓰는 보조 타입은
[View 내부 선언 컨벤션 §2](./view-declarations.md#2-view-내부-선언)에 따라 그 화면에
중첩합니다.

### 3.5 접근 수준

- UIComponent의 컴포넌트: `public`
- 프리뷰 전용 타입: `internal`
- Feature 화면: App이 목적지로 생성하는 화면만 `public`, 다른 화면 안에서만
  생성되는 화면은 `internal`
- UI 컴포넌트에 중첩한 `Style`과 그 밖의 비상태 보조 타입: 공개 계약에 필요한 경우만
  `public`, 그 외에는 `private`
- View가 소유한 `Constant`와 그 밖의 보조 선언: 항상 `private`([View 내부 선언 컨벤션 §2.1](./view-declarations.md#21-constant))

"모든 화면을 `public`으로 연다"와 "필요할 때 연다"를 파일마다 다르게 적용하지
않습니다. 화면을 `public`으로 여는 근거는 App의 Navigation에서 생성되는지 여부
하나입니다.

`Style`은 호출부가 직접 선택하는 공개 초기화 경로에 필요할 때만 `public`으로 엽니다.
표시 상태 wrapper는 접근 수준과 관계없이 정의하지 않습니다. Feature 화면의 상태 계약은
Reducer의 `State`가 소유합니다.

## 4. 화면 조립

### 4.1 화면 골격

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

### 4.2 화면이 소유하는 것과 소유하지 않는 것

- 화면은 상태 분기, 화면 목적지 생성, 컴포넌트 조립을 소유합니다.
- 화면에서 독립적으로 이름 붙일 수 있는 표현 책임은 UIComponent로 옮깁니다.
- 화면 전용 렌더링 조각은 §4.3의 화면 전용 서브뷰로 분리하고, 패키지 수준의 재사용
  `View` 타입으로 노출하지 않습니다.

화면이 Store와 Action을 다루는 경계는
[TCA Navigation 컨벤션 §2.2](./tca/navigation.md#22-tca-화면)를 따릅니다.

### 4.3 화면 전용 서브뷰

**UIComponent가 지원하지 않는 표현이면서 한 화면에서만 쓰는 렌더링 조각은, 화면
타입에 중첩한 `View` 타입으로 정의해 화면에서 그 책임을 분리합니다.** 재사용 가능한
표현이면 서브뷰로 만들지 않고
[UIComponent 컨벤션 §4](./ui-component.md#4-재사용-판단)에 따라 컴포넌트로 옮깁니다.

```swift
// ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen+ThumbnailView.swift
extension RepositoryConfirmationScreen {
    struct ThumbnailView: View {
        var body: some View { ... }

        private enum Constant {
            static let cornerRadius: CGFloat = 12
        }
    }
}
```

- 서브뷰는 화면 타입에 중첩합니다. 화면 파일 최상위나 다른 화면에서 참조할 수 있는
  위치에 두지 않습니다.
- **화면 `body`에서 서브뷰를 호출할 때는 `Self.`을 붙입니다.** 그 표현이 이 화면이
  소유한 서브뷰라는 것을 호출부에서 바로 드러내기 위한 것입니다
  (`Self.ThumbnailView()`).
- 서브뷰의 상수는 화면과 같은 방식으로 **서브뷰 자신의 `Constant`** 에 정의합니다.
  부모 화면의 `Constant`를 직접 참조하지 않으며, 같은 값을 써야 하면 서브뷰 생성자로
  주입받고 부모 화면이 초기화 시 넘깁니다
  ([View 내부 선언 컨벤션 §2.1](./view-declarations.md#21-constant)).
- **서브뷰는 SwiftUI와 UI 패키지에만 의존합니다.** 서브뷰 파일이 `import`할 수 있는
  것은 `SwiftUI`, `DesignSystem`, `UIComponent`와 `Foundation`·`CoreGraphics`뿐입니다.
  `ComposableArchitecture`와 Domain 패키지를 import하면 규칙 위반이며, 이것이 이
  규칙의 기계적 확인 기준입니다.
- 따라서 `StoreOf<Feature>`, `Feature.State.*`, `Action`, Domain 모델을 서브뷰의
  입력으로 쓰지 않습니다. **화면이 그 값을 표시 값으로 변환해 전달합니다** — 문자열,
  숫자, `Bool`, 콜백, 그리고 UIComponent가 정의한 타입입니다.
- 화면이 서브뷰에게 이름 붙인 경계가 필요하면 화면 파일에 `typealias`로 정의합니다.
  같은 모듈이라 import가 필요 없으므로 위 제약을 지키면서 이름을 줄 수 있습니다.
  값을 담는 표시 타입은 화면에 중첩하지 않고 최상위 타입으로 분리합니다
  ([View 내부 선언 컨벤션 §2.2](./view-declarations.md#22-private을-붙일-수-없으면-소유가-잘못된-것입니다)).

  ```swift
  extension HomeScreen {
      struct ProfileHeaderView: View {
          let name: String?
          let role: String
          let isFailed: Bool
          let onRetry: () -> Void
      }
  }
  ```

  화면은 `HomeFeature.State.ProfileLoad`를 읽어 이 값들을 만들어 넘깁니다. 서브뷰는
  Feature도 Domain도 모릅니다.

- 화면 파일이 길어지면 서브뷰를
  [파일·형태 어휘 컨벤션 §2.2](./file-vocabulary.md#22-중첩-타입-분리)의
  `{화면}+{서브뷰}.swift`로 나누고, 그 화면 폴더의 `SubViews/`에 둡니다
  ([디렉터리·파일 컨벤션 §4.3](./directory-file.md#43-feature-패키지의-흐름-배치)).

### 4.4 표시용 표본 데이터

레이아웃 검토 단계의 화면이 참조하는 표본 데이터는 화면 파일에 하드코딩하지 않고
`Shared/Models/`의 `internal` 표본 타입에 모읍니다. 표본 타입은 컴포넌트
입력 타입이 아니며 UI 패키지로 넘기지 않습니다.

화면이 실제 상태에 연결될 때 표본 참조는 Feature `State`에서 파생한 표시 값이나
SwiftUI `Binding`으로 대체하고, 표본 타입은 해당 화면의 참조가 모두 사라진 시점에
제거합니다.

## 5. 프리뷰

| 대상 | 위치 | 이름 |
|---|---|---|
| UIComponent | 컴포넌트 파일 하단 `#Preview` | 컴포넌트 이름 |
| Feature 화면 | 그 화면 폴더의 `Previews/` 안 `<화면 타입 이름>Previews.swift` | 화면과 상태를 설명하는 한국어 이름 |

- 컴포넌트 프리뷰는 모든 시각 변형을 한 프리뷰에 나열해 변형 간 차이를 함께 봅니다.
- 컴포넌트 프리뷰의 배경은 `designSystemBackground(.grey700)`으로 실제 화면 배경 위의
  대비를 확인합니다.
- 화면 프리뷰는 `catalogPreviewFrame()`으로 동일한 검토 프레임을 사용합니다.
- 화면 파일 안에 `#Preview`를 두지 않습니다. 화면 프리뷰는 상태 조합마다 늘어나므로
  화면 구현과 분리합니다.
- **Feature 프리뷰 파일은 언제나 `Previews/` 폴더로 분리합니다.** 한 화면의 프리뷰는 그
  화면 폴더의 `Previews/`에, 여러 화면이 함께 쓰는 프리뷰 전용 지원 타입은 흐름 1뎁스의
  `Previews/`에 둡니다
  ([디렉터리·파일 컨벤션 §4.3](./directory-file.md#43-feature-패키지의-흐름-배치)).
- 파일 이름은 화면 타입 이름 뒤에 `Previews`를 붙입니다 —
  `RepositoryConfirmationScreenPreviews.swift`, `OnboardingRouterPreviews.swift`.
- 프리뷰 전용 타입은 프리뷰가 필요한 컴포넌트 파일이 아니라 독립 파일에 둡니다.

## 6. 검토 체크리스트

### 공개 계약

- [ ] 컴포넌트의 공개 생성 경로가 표시 값·`Binding`·콜백을 직접 받는 초기화 메서드와
      시각 변형 팩토리뿐인가?
- [ ] 표시 상태를 묶는 `ViewModel`, `State` 또는 동등한 wrapper가 없는가?
- [ ] 팩토리 이름이 Feature 업무 역할이 아니라 시각 의미를 표현하는가?
- [ ] 변경 가능한 외부 상태는 `Binding`, 일회성 입력은 콜백으로 구분되는가?
- [ ] UI 컴포넌트 계약과 구현에 TCA `Store`, `Action`, `Effect` 또는 dependency 접근
      타입이 없는가?
- [ ] Feature 화면이 `StoreOf<Feature>`를 초기화 인자로 받고 별도 화면 `ViewModel`을
      만들지 않는가?
- [ ] 화면의 `public` 여부가 App Navigation 생성 여부와 일치하는가?

### 화면 조립과 프리뷰

- [ ] 화면 전용 서브뷰가 화면 타입에 중첩되어 있고, `body`에서 `Self.`으로
      호출되는가?
- [ ] 재사용 가능한 표현을 화면 전용 서브뷰로 남겨 두지 않았는가?
- [ ] 서브뷰 파일의 `import`가 SwiftUI·DesignSystem·UIComponent로 한정되는가?
- [ ] 서브뷰 입력에 `Store`·Feature `State`·Domain 모델이 없는가?
- [ ] 화면이 `preferredColorScheme`을 다시 지정하지 않는가?
- [ ] 검토 전용 UI가 `UIComponentPreviewApp` target에 있는가?
- [ ] 컴포넌트 프리뷰가 모든 시각 변형을 포함하는가?
- [ ] 화면 프리뷰가 그 화면 폴더의 `Previews/` 안 `<화면 타입 이름>Previews.swift`에 있는가?

디자인 토큰과 View 내부 선언의 체크리스트는 각 문서 —
[View 토큰 컨벤션](./view-tokens.md#3-검토-체크리스트),
[View 내부 선언 컨벤션](./view-declarations.md#3-검토-체크리스트) — 이 소유합니다.

## 관련 문서

- [아키텍처](../architecture.md)
- [네이밍 컨벤션](./naming.md)
- [View 토큰 컨벤션](./view-tokens.md)
- [View 내부 선언 컨벤션](./view-declarations.md)
- [UIComponent 컨벤션](./ui-component.md)
- [TCA 컨벤션](./tca/README.md)
- [UI 패키지 규칙](../package-rules/ui.md)
- [Feature 패키지 규칙](../package-rules/feature.md)

## 문서 변경 기준

공개 생성 경로, 화면 조립 또는 프리뷰 배치 규칙이 바뀔 때 수정합니다. 디자인 토큰
사용 규칙이 바뀌면 이 문서가 아니라 [View 토큰 컨벤션](./view-tokens.md)을, View
내부 선언(`Constant`, `Style`, 중첩 규칙)이 바뀌면
[View 내부 선언 컨벤션](./view-declarations.md)을 갱신합니다. 한 패키지에만 적용되는
규칙은 해당 패키지 규칙 문서에서 관리합니다.
