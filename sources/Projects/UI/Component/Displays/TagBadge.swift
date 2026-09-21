import DesignSystem
import SwiftUI

// MARK: - TagBadge

public struct TagBadge: View {

    // MARK: Lifecycle

    public init(text: String) {
        self.text = text
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

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 10
        static let topPadding: CGFloat = 3
        static let bottomPadding: CGFloat = 4
    }

    private let text: String
    private var style = Style.neutral
    private var size = Size.regular

}

// MARK: StyleConfigurable

extension TagBadge: StyleConfigurable {
    public func style(_ style: Style) -> Self {
        var copy = self
        copy.style = style
        return copy
    }
}

// MARK: SizeConfigurable

extension TagBadge: SizeConfigurable {
    public func size(_ size: Size) -> Self {
        var copy = self
        copy.size = size
        return copy
    }
}

#Preview("Tag Badge") {
    HStack(spacing: LayoutToken.gutter) {
        TagBadge(text: "Neutral")
        TagBadge(text: "Accent")
            .style(.accent)
        TagBadge(text: "Selected")
            .style(.selected)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
