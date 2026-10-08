# `Style`

[Git It iOS View 내부 선언 컨벤션](../view-declarations.md)의 규칙 문서입니다.

고정된 토큰 조합을 갖는 시각 변형이 **둘 이상일 때만** `Style`을 정의합니다. 변형이
하나뿐인 View는 `Style`을 정의하지 않으며, 화면은 시각 변형이 아니라 화면 상태를
입력받으므로 `Style`을 갖지 않습니다([View 컨벤션 — 화면의 생성 경로](../view/screen-init.md)).

변형에 따라 갈리는 표현 값은 View의 연산 프로퍼티에서 `switch`로 분기하지 않고 `Style`이
소유합니다. View는 `style.titleColor(isEnabled:)`처럼 결과만 읽습니다. 변형이
늘어날 때 고쳐야 할 위치를 열거형 한 곳으로 모으기 위한 것입니다.

```swift
// Controls/ActionButton.swift
public struct ActionButton: View {
    public init(
        title: String,
        action: @escaping () -> Void = { },
    ) {
        self.title = title
        self.action = action
    }

    public enum Style: Sendable, Equatable {
        case primary
        case secondary
        case destructive

        func titleColor(isEnabled: Bool) -> ColorToken {
            guard isEnabled else { return .white30 }

            switch self {
            case .primary: return .grey700
            case .secondary, .destructive: return .grey100
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
    private var style = Style.primary
    private var isEnabled = true
    private let action: () -> Void

    private enum Constant {
        static let controlHeight: CGFloat = 54
    }
}

extension ActionButton: StyleConfigurable {
    public func style(_ style: Style) -> Self {
        var copy = self
        copy.style = style
        return copy
    }
}

// 호출부
ActionButton(title: "삭제") { store.send(.deleteTapped) }
    .style(.destructive)
```

`Style`은 상태를 담지 않으며 시각 변형만 소유합니다. 호출부는 `Style`을 생성 시점에
넘기지 않고, `StyleConfigurable`의 `style(_:)` 메서드로 변형을 선택합니다. 컴포넌트는
`Style`을 기본값이 있는 `private var`로 저장하고, `style(_:)`은 그 값을 바꾼 복사본을
반환합니다. 여러 번 호출하면 마지막 호출이 적용됩니다. 초기화 메서드 구성과 시각 속성
계약의 전체 규칙은 [View 컨벤션 — 컴포넌트의 공개 생성 경로](../view/component-init.md)를
따릅니다.
