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
[View 컨벤션 — 공개 생성 경로](../view/component-init.md)의 시각
변형 팩토리를 기본 선택 수단으로 사용합니다.
