import DesignSystem
import SwiftUI

public struct ActionButton: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        action: @escaping () -> Void = { },
    ) {
        self.viewModel = viewModel
        self.action = action
    }

    // MARK: Public

    public enum Style: Sendable, Equatable {
        case primary
        case secondary
        case destructive
        case text

        // MARK: Internal

        /// 채워진 스타일만 비활성에서 `raisedBackground`로 내려가고 `text`는 투명을 유지합니다.
        func backgroundColor(isEnabled: Bool) -> Color {
            switch self {
            case .text:
                return .clear

            case .secondary:
                return Color(designSystem: SemanticColorToken.raisedBackground)

            case .primary:
                guard isEnabled else { return Color(designSystem: SemanticColorToken.raisedBackground) }
                return Color(designSystem: SemanticColorToken.brandAccent)

            case .destructive:
                guard isEnabled else { return Color(designSystem: SemanticColorToken.raisedBackground) }
                return Color(designSystem: ColorToken.error)
            }
        }

        func titleColor(isEnabled: Bool) -> ColorToken {
            guard isEnabled else { return .white30 }

            switch self {
            case .primary:
                return .grey700
            case .secondary,
                 .destructive,
                 .text:
                return .grey100
            }
        }
    }

    /// 기본 문구는 `title`, 서식이 필요한 문구는 `styled`로 전달합니다.
    public enum Label: Sendable, Equatable {
        case title(String)
        case styled(StyledText.ViewModel)
    }

    public struct ViewModel: Sendable, Equatable {

        // MARK: Lifecycle

        public init(
            title: String,
            style: Style = .primary,
            isEnabled: Bool = true,
        ) {
            label = .title(title)
            self.style = style
            self.isEnabled = isEnabled
        }

        public init(
            styledText: StyledText.ViewModel,
            style: Style = .primary,
            isEnabled: Bool = true,
        ) {
            label = .styled(styledText)
            self.style = style
            self.isEnabled = isEnabled
        }

        // MARK: Public

        public let label: Label
        public let style: Style
        public let isEnabled: Bool

    }

    public var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity)
                .designSystemControlHeight(.action)
                .background(
                    viewModel.style.backgroundColor(isEnabled: viewModel.isEnabled),
                    in: RoundedRectangle(designSystem: .large),
                )
        }
        .disabled(!viewModel.isEnabled)
    }

    public static func primary(
        _ title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(title: title, style: .primary, isEnabled: isEnabled),
            action: action,
        )
    }

    public static func primary(
        styledText: StyledText.ViewModel,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(styledText: styledText, style: .primary, isEnabled: isEnabled),
            action: action,
        )
    }

    public static func secondary(
        _ title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(title: title, style: .secondary, isEnabled: isEnabled),
            action: action,
        )
    }

    public static func secondary(
        styledText: StyledText.ViewModel,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(styledText: styledText, style: .secondary, isEnabled: isEnabled),
            action: action,
        )
    }

    public static func destructive(
        _ title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(title: title, style: .destructive, isEnabled: isEnabled),
            action: action,
        )
    }

    public static func destructive(
        styledText: StyledText.ViewModel,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(styledText: styledText, style: .destructive, isEnabled: isEnabled),
            action: action,
        )
    }

    public static func text(
        _ title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(title: title, style: .text, isEnabled: isEnabled),
            action: action,
        )
    }

    public static func text(
        styledText: StyledText.ViewModel,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(styledText: styledText, style: .text, isEnabled: isEnabled),
            action: action,
        )
    }

    // MARK: Private

    private let viewModel: ViewModel
    private let action: () -> Void

    /// `title`은 버튼 스타일이 정한 색을 입히고, `styled`는 전달된 서식을 그대로 사용합니다.
    @ViewBuilder
    private var content: some View {
        switch viewModel.label {
        case .title(let title):
            Text.designSystemStyled(title, style: .body1)
                .designSystemLineSpacing(.body1)
                .designSystemForeground(viewModel.style.titleColor(isEnabled: viewModel.isEnabled))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

        case .styled(let styledText):
            StyledText(viewModel: styledText)
        }
    }

}

#Preview("Action Button") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ActionButton.primary("Primary")
        ActionButton.secondary("Secondary")
        ActionButton.destructive("Destructive")
        ActionButton.text("Text")
        ActionButton.primary("Disabled", isEnabled: false)
        ActionButton.text("Disabled Text", isEnabled: false)
//        ActionButton.primary(styledText: .subtitle2("Styled Label", color: .grey700, alignment: .center))
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
