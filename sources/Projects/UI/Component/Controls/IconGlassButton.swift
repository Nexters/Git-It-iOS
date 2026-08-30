import DesignSystem
import SwiftUI

public struct IconGlassButton: View {

    // MARK: Lifecycle

    public init(
        symbol: String,
        label: String,
        style: Style = .neutral,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) {
        self.symbol = symbol
        self.label = label
        self.style = style
        self.size = size
        self.action = action
    }

    // MARK: Public

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
                17
            case .small:
                15
            }
        }

        var touchSize: CGFloat {
            44
        }
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size.iconSize))
                .designSystemForeground(style.tintColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(width: size.surfaceSize, height: size.surfaceSize)
                .glassEffect(
                    .regular
                        .tint(Color(designSystem: style.backgroundColor))
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
        symbol: String,
        label: String,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(symbol: symbol, label: label, style: .neutral, size: size, action: action)
    }

    public static func accent(
        symbol: String,
        label: String,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(symbol: symbol, label: label, style: .accent, size: size, action: action)
    }

    public static func destructive(
        symbol: String,
        label: String,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(symbol: symbol, label: label, style: .destructive, size: size, action: action)
    }

    // MARK: Private

    private let symbol: String
    private let label: String
    private let style: Style
    private let size: Size
    private let action: () -> Void

}

#Preview("Icon Glass Button") {
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        HStack(spacing: LayoutToken.gutter.cgFloatValue) {
            IconGlassButton.neutral(symbol: "chevron.left", label: "뒤로 가기")
            IconGlassButton.accent(symbol: "bookmark", label: "저장하기")
            IconGlassButton.destructive(symbol: "trash", label: "삭제하기")
        }
        HStack(spacing: LayoutToken.gutter.cgFloatValue) {
            IconGlassButton.neutral(symbol: "chevron.left", label: "뒤로 가기", size: .small)
            IconGlassButton.accent(symbol: "bookmark", label: "저장하기", size: .medium)
        }
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.blue500)
}
