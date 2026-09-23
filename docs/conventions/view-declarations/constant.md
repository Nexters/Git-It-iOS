# `Constant`

[Git It iOS View 내부 선언 컨벤션](../view-declarations.md)의 규칙 문서입니다.

상태와 무관한 수치, 사용자에게 보이지 않는 정적 문자열, 플레이스홀더는 case 없는 `Constant`의
`static` 멤버로 정의합니다. 비제네릭 View는 `static let` 저장 프로퍼티를 사용합니다. 사용자 노출
문구는 `Constant`가 아니라 [현지화 컨벤션 §4.1](../localization.md#41-localizedtext)의
`LocalizedText`가 소유합니다.

**최상위 View는 파일 하단의 `private extension`에 `Constant`를 정의합니다.** `body`를
읽는 흐름이 상수 목록으로 끊기지 않게 하고, `private`을 extension 하나에 붙여 View 밖
참조를 막기 위한 것입니다.

```swift
struct RepositoryLinkInputScreen: View {
    var body: some View { ... }
}

private extension RepositoryLinkInputScreen {
    enum Constant {
        static let titleFieldSpacing: CGFloat = 16
        static let bottomButtonPadding: CGFloat = 34
    }
}
```

**중첩 서브뷰는 자기 타입 안에 `private enum Constant`로 둡니다.** 서브뷰는 이미
`{화면}+{서브뷰}.swift`라는 자기 파일을 갖고 있어 상수가 `body`에서 멀지 않고,
extension으로 다시 꺼내면 `화면.서브뷰` 전체 경로를 반복해야 합니다. 부모 화면의
`Constant`를 직접 참조하지 않고, 같은 값을 써야 하면 서브뷰 생성자로 주입받아 부모
화면이 초기화 시 넘깁니다. 서브뷰를 언제 만드는지와 호출 규칙은
[View 컨벤션 — 화면 전용 서브뷰](../view/screen-subview.md)이 소유합니다.

```swift
extension RepositoryLinkInputScreen {
    struct GuideSectionView: View {
        var body: some View { ... }

        private enum Constant {
            static let rowSpacing: CGFloat = 12
        }
    }
}
```

**그 View 안에서만 참조하는 디자인 토큰 값도 같은 방식으로 정의합니다.** `ColorToken`,
`TextStyleToken`처럼
[View 토큰 컨벤션 §2](../view-tokens.md#2-디자인-토큰)의 토큰 카탈로그를 참조하는
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
[View 토큰 컨벤션 — 레이아웃·모서리·컨트롤 크기](../view-tokens/layout-metrics.md)의 기준에 따라
DesignSystem 토큰으로 승격합니다. `Constant`는 그 View 하나에서만 의미를 갖는
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
- **`Constant`는 `{View}+Constant.swift`처럼 별도 파일로 나누지 않습니다.** 상수는
  `body`를 읽을 때 곧바로 확인해야 하는 값이라 같은 파일에 있어야 하고, 파일을 나누면
  `private`을 쓸 수 없어 View 밖에서 참조할 길이 열립니다.

다음은 상수로 승격하지 않습니다.

- `0`, `1`, `.infinity`처럼 값 자체가 의미인 레이아웃 값
- `lineLimit`, `ForEach` 범위처럼 이름이 설명을 더하지 않는 값

그 외에 **한 파일에서 두 번 이상 나타나거나, 이름 없이는 의미가 드러나지 않는
수치**는 `Constant`에 둡니다.
