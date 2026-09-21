import DesignSystem
import SwiftUI

// MARK: - ActionButton

public struct ActionButton: View {

    // MARK: Lifecycle

    public init(
        title: String,
        action: @escaping () -> Void = { },
    ) {
        label = .title(title)
        self.action = action
    }

    public init(
        styledText: StyledText,
        action: @escaping () -> Void = { },
    ) {
        label = .styled(styledText)
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
                return Color(designSystem: ColorToken.grey500)

            case .primary:
                guard isEnabled else { return Color(designSystem: ColorToken.grey500) }
                return Color(designSystem: ColorToken.blue100)

            case .destructive:
                guard isEnabled else { return Color(designSystem: ColorToken.grey500) }
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
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .frame(minHeight: size.touchHeight)
        .contentShape(Rectangle())
        .background(
            style.backgroundColor(isEnabled: isEnabled),
            in: RoundedRectangle(designSystem: .large),
        )
    }

    // MARK: Private

    private enum Label: Sendable, Equatable {
        case title(String)
        case styled(StyledText)
    }

    private let label: Label
    private var style = Style.primary
    private var size = Size.large
    private var isEnabled = true
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

// MARK: StyleConfigurable

extension ActionButton: StyleConfigurable {
    public func style(_ style: Style) -> Self {
        var copy = self
        copy.style = style
        return copy
    }
}

// MARK: SizeConfigurable

extension ActionButton: SizeConfigurable {
    public func size(_ size: Size) -> Self {
        var copy = self
        copy.size = size
        return copy
    }
}

// MARK: ActionButton 상태 선언

extension ActionButton {
    public func enabled(_ isEnabled: Bool) -> Self {
        var copy = self
        copy.isEnabled = isEnabled
        return copy
    }
}

#Preview("Action Button") {
    VStack(spacing: LayoutToken.gutter) {
        ActionButton(title: "Primary")
        ActionButton(title: "Secondary")
            .style(.secondary)
        ActionButton(title: "Destructive")
            .style(.destructive)
        ActionButton(title: "Text")
            .style(.text)
        ActionButton(title: "Disabled")
            .enabled(false)
        ActionButton(title: "Disabled Text")
            .enabled(false)
            .style(.text)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
