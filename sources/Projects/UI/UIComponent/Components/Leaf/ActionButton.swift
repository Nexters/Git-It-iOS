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

    public struct ViewModel: Sendable, Equatable {
        public init(
            title: String,
            style: Style = .primary,
            isEnabled: Bool = true,
        ) {
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
                .designSystemLineSpacing(.body1)
                .designSystemForeground(viewModel.style.titleColor(isEnabled: viewModel.isEnabled))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
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

    // MARK: Private

    private let viewModel: ViewModel
    private let action: () -> Void

}

#Preview("Action Button") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ActionButton.primary("Primary")
        ActionButton.secondary("Secondary")
        ActionButton.destructive("Destructive")
        ActionButton.text("Text")
        ActionButton.primary("Disabled", isEnabled: false)
        ActionButton.text("Disabled Text", isEnabled: false)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
