import DesignSystem
import SwiftUI

public struct ActionButton: View {

    // MARK: Lifecycle

    public init(
        title: String,
        style: Style = .primary,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) {
        label = .title(title)
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }

    public init(
        styledText: StyledText,
        style: Style = .primary,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) {
        label = .styled(styledText)
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }

    // MARK: Public

    public enum Style: Sendable, Equatable {
        case primary
        case secondary
        case destructive
        case text
        case primaryText

        // MARK: Internal

        func backgroundColor(isEnabled: Bool) -> Color {
            switch self {
            case .text,
                 .primaryText:
                return Color(designSystem: ColorToken.clear)

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
            case .primaryText:
                return .blue100
            case .secondary,
                 .destructive,
                 .text:
                return .grey100
            }
        }
    }

    public enum Size: Sendable, Equatable {
        case large
        case medium
        case small

        // MARK: Internal

        var surfaceHeight: CGFloat {
            switch self {
            case .large:
                54
            case .medium:
                40
            case .small:
                36
            }
        }

        var minimumHitArea: CGFloat {
            ControlSizeToken.minimumTouch.cgFloatValue
        }

        var touchHeight: CGFloat {
            max(surfaceHeight, minimumHitArea)
        }
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                content
                    .frame(maxWidth: .infinity)
                    .frame(height: size.surfaceHeight)
                    .background(
                        style.backgroundColor(isEnabled: isEnabled),
                        in: RoundedRectangle(designSystem: .large),
                    )
            }
            .frame(minHeight: size.touchHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    public static func primary(
        _ title: String,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            title: title,
            style: .primary,
            size: size,
            isEnabled: isEnabled,
            action: action,
        )
    }

    public static func primary(
        styledText: StyledText,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            styledText: styledText,
            style: .primary,
            size: size,
            isEnabled: isEnabled,
            action: action,
        )
    }

    public static func secondary(
        _ title: String,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            title: title,
            style: .secondary,
            size: size,
            isEnabled: isEnabled,
            action: action,
        )
    }

    public static func secondary(
        styledText: StyledText,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            styledText: styledText,
            style: .secondary,
            size: size,
            isEnabled: isEnabled,
            action: action,
        )
    }

    public static func destructive(
        _ title: String,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            title: title,
            style: .destructive,
            size: size,
            isEnabled: isEnabled,
            action: action,
        )
    }

    public static func destructive(
        styledText: StyledText,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            styledText: styledText,
            style: .destructive,
            size: size,
            isEnabled: isEnabled,
            action: action,
        )
    }

    public static func text(
        _ title: String,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            title: title,
            style: .text,
            size: size,
            isEnabled: isEnabled,
            action: action,
        )
    }

    public static func text(
        styledText: StyledText,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            styledText: styledText,
            style: .text,
            size: size,
            isEnabled: isEnabled,
            action: action,
        )
    }

    public static func primaryText(
        _ title: String,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            title: title,
            style: .primaryText,
            size: size,
            isEnabled: isEnabled,
            action: action,
        )
    }

    // MARK: Private

    private enum Label: Sendable, Equatable {
        case title(String)
        case styled(StyledText)
    }

    private let label: Label
    private let style: Style
    private let size: Size
    private let isEnabled: Bool
    private let action: () -> Void

    @ViewBuilder
    private var content: some View {
        switch label {
        case .title(let title):
            Text.designSystemStyled(title, style: .body1)
                .designSystemLineSpacing(.body1)
                .designSystemForeground(style.titleColor(isEnabled: isEnabled))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

        case .styled(let styledText):
            styledText
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
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
