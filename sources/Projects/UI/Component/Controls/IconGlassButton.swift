import DesignSystem
import SwiftUI

public struct IconGlassButton: View {

    // MARK: Lifecycle

    public init(
        icon: Icon,
        label: String,
        style: Style = .neutral,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) {
        self.icon = icon
        self.label = label
        self.style = style
        self.size = size
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
                .frame(width: size.iconSize, height: size.iconSize)
                .designSystemForeground(style.tintColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(width: size.surfaceSize, height: size.surfaceSize)
                .glassEffect(
                    .regular
                        .tint(Color(designSystem: .clear))
                        .interactive(),
                    in: .circle,
                )
                .frame(width: size.touchSize, height: size.touchSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    public static func neutral(
        icon: Icon,
        label: String,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(icon: icon, label: label, style: .neutral, size: size, action: action)
    }

    public static func accent(
        icon: Icon,
        label: String,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(icon: icon, label: label, style: .accent, size: size, action: action)
    }

    public static func destructive(
        icon: Icon,
        label: String,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(icon: icon, label: label, style: .destructive, size: size, action: action)
    }

    // MARK: Private

    private let icon: Icon
    private let label: String
    private let style: Style
    private let size: Size
    private let action: () -> Void

}

#Preview("Icon Glass Button") {
    VStack(spacing: LayoutToken.margin) {
        HStack(spacing: LayoutToken.gutter) {
            IconGlassButton.neutral(icon: .chevronLeft, label: "뒤로 가기")
            IconGlassButton.accent(icon: .bookmark, label: "저장하기")
            IconGlassButton.destructive(icon: .minus, label: "삭제하기")
        }
        HStack(spacing: LayoutToken.gutter) {
            IconGlassButton.neutral(icon: .chevronLeft, label: "뒤로 가기", size: .small)
            IconGlassButton.accent(icon: .bookmark, label: "저장하기", size: .medium)
        }
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.blue500)
}
