import DesignSystem
import SwiftUI

public struct TagBadge: View {

    // MARK: Lifecycle

    public init(
        text: String,
        style: Style = .neutral,
    ) {
        self.text = text
        self.style = style
    }

    // MARK: Public

    public enum Style: Sendable, Equatable {
        case neutral
        case accent
        case selected

        // MARK: Internal

        var backgroundColor: ColorToken {
            switch self {
            case .neutral: .grey500
            case .accent: .blue100
            case .selected: .blue400
            }
        }

        /// `accent`는 배경이 강조색이므로 전경을 어둡게 뒤집어 대비를 확보합니다.
        var textColor: ColorToken {
            switch self {
            case .neutral: .blue100
            case .accent: .grey700
            case .selected: .grey100
            }
        }
    }

    public var body: some View {
        Text.designSystemStyled(text, style: .body2)
            .designSystemLineSpacing(.body2)
            .designSystemForeground(style.textColor)
            .padding(.horizontal, Constant.horizontalPadding)
            .padding(.top, Constant.topPadding)
            .padding(.bottom, Constant.bottomPadding)
            .background(
                Color(designSystem: style.backgroundColor),
                in: RoundedRectangle(designSystem: .small),
            )
    }

    public static func neutral(_ text: String) -> Self {
        Self(text: text, style: .neutral)
    }

    public static func accent(_ text: String) -> Self {
        Self(text: text, style: .accent)
    }

    public static func selected(_ text: String) -> Self {
        Self(text: text, style: .selected)
    }

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 10
        static let topPadding: CGFloat = 3
        static let bottomPadding: CGFloat = 4
    }

    private let text: String
    private let style: Style

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
