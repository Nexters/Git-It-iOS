import DesignSystem
import SwiftUI

public struct TagBadge: View {

    // MARK: Lifecycle

    public init(
        text: String,
        style: Style = .neutral,
        size: Size = .regular,
    ) {
        self.text = text
        self.style = style
        self.size = size
    }

    // MARK: Public

    public enum Style: Sendable, Equatable {
        case neutral
        case accent
        case selected
        case muted

        // MARK: Internal

        var backgroundColor: ColorToken {
            switch self {
            case .neutral: .grey500
            case .accent: .blue400
            case .selected: .blue400
            case .muted: .grey500
            }
        }

        var textColor: ColorToken {
            switch self {
            case .neutral: .blue100
            case .accent: .blue100
            case .selected: .grey100
            case .muted: .grey300
            }
        }
    }

    public enum Size: Sendable, Equatable {
        case regular
        case compact

        // MARK: Internal

        var textStyle: TextStyleToken {
            switch self {
            case .regular: .body2
            case .compact: .body3
            }
        }
    }

    public var body: some View {
        Text.designSystemStyled(text, style: size.textStyle)
            .designSystemLineSpacing(size.textStyle)
            .designSystemForeground(style.textColor)
            .padding(.horizontal, Constant.horizontalPadding)
            .padding(.top, Constant.topPadding)
            .padding(.bottom, Constant.bottomPadding)
            .background(
                Color(designSystem: style.backgroundColor),
                in: RoundedRectangle(designSystem: .small),
            )
    }

    public static func neutral(
        _ text: String,
        size: Size = .regular,
    ) -> Self {
        Self(text: text, style: .neutral, size: size)
    }

    public static func accent(
        _ text: String,
        size: Size = .regular,
    ) -> Self {
        Self(text: text, style: .accent, size: size)
    }

    public static func selected(
        _ text: String,
        size: Size = .regular,
    ) -> Self {
        Self(text: text, style: .selected, size: size)
    }

    public static func muted(
        _ text: String,
        size: Size = .compact,
    ) -> Self {
        Self(text: text, style: .muted, size: size)
    }

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 10
        static let topPadding: CGFloat = 3
        static let bottomPadding: CGFloat = 4
    }

    private let text: String
    private let style: Style
    private let size: Size

}

#Preview("Tag Badge") {
    HStack(spacing: LayoutToken.gutter.cgFloatValue) {
        TagBadge.neutral("Neutral")
        TagBadge.accent("Accent")
        TagBadge.selected("Selected")
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
