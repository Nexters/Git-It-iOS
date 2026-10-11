import DesignSystem
import SwiftUI

// MARK: - IconGlassButton

public struct IconGlassButton: View {

    // MARK: Lifecycle

    public init(
        icon: Icon,
        action: @escaping () -> Void = { },
    ) {
        self.icon = icon
        self.action = action
    }

    // MARK: Public

    public typealias Icon = ResourceImage.Asset.Icon

    public enum Style: Sendable, Equatable {
        case neutral
        case accent
        case destructive

        var tintColor: ColorToken {
            switch self {
            case .neutral: .grey100
            case .accent: .blue100
            case .destructive: .error
            }
        }

        var backgroundColor: ColorToken {
            switch self {
            case .neutral: .white5
            case .accent: .grey500
            case .destructive: .grey700
            }
        }
    }

    public enum Size: Sendable, Equatable {
        case medium
        case small

        // MARK: Internal

        var surfaceSize: CGFloat {
            switch self {
            case .medium:
                40
            case .small:
                36
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .medium:
                24
            case .small:
                20
            }
        }

        var touchSize: CGFloat {
            ControlSizeToken.minimumTouch.cgFloatValue
        }
    }

    public var body: some View {
        Button(action: action) {
            ResourceImage(asset: .icon(icon))
                .frame(
                    width: size.iconSize,
                    height: size.iconSize,
                )
                .designSystemForeground(style.tintColor)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                )
                .frame(
                    width: size.surfaceSize,
                    height: size.surfaceSize,
                )
                .glassEffect(
                    .regular
                        .tint(Color(designSystem: .clear))
                        .interactive(),
                    in: .circle,
                )
                .frame(
                    width: size.touchSize,
                    height: size.touchSize,
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    private let icon: Icon
    private var style = Style.neutral
    private var size = Size.small
    private let action: () -> Void

}

// MARK: StyleConfigurable

extension IconGlassButton: StyleConfigurable {
    public func style(_ style: Style) -> Self {
        var copy = self
        copy.style = style
        return copy
    }
}

// MARK: SizeConfigurable

extension IconGlassButton: SizeConfigurable {
    public func size(_ size: Size) -> Self {
        var copy = self
        copy.size = size
        return copy
    }
}

#Preview("Icon Glass Button") {
    VStack(spacing: LayoutToken.margin) {
        HStack(spacing: LayoutToken.gutter) {
            IconGlassButton(
                icon: .chevronLeft
            )
            IconGlassButton(
                icon: .bookmark
            )
            .style(.accent)
            IconGlassButton(
                icon: .minus
            )
            .style(.destructive)
        }
        HStack(spacing: LayoutToken.gutter) {
            IconGlassButton(
                icon: .chevronLeft
            )
            IconGlassButton(
                icon: .bookmark
            )
            .style(.accent)
            .size(.medium)
        }
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.blue500)
}
