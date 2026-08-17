import DesignSystem
import SwiftUI

public struct TagBadge: View {

    // MARK: Lifecycle

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Public

    public enum Style: Sendable, Equatable {
        case neutral
        case accent
        case selected

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

    public struct ViewModel: Sendable, Equatable {
        public init(
            text: String,
            style: Style = .neutral,
        ) {
            self.text = text
            self.style = style
        }

        public let text: String
        public let style: Style
    }

    public var body: some View {
        Text.designSystemStyled(viewModel.text, style: .body2)
            .designSystemLineSpacing(.body2)
            .designSystemForeground(viewModel.style.textColor)
            .padding(.horizontal, Constant.horizontalPadding)
            .padding(.top, Constant.topPadding)
            .padding(.bottom, Constant.bottomPadding)
            .background(
                Color(designSystem: viewModel.style.backgroundColor),
                in: RoundedRectangle(designSystem: .small),
            )
    }

    public static func neutral(_ text: String) -> Self {
        Self(viewModel: .init(text: text, style: .neutral))
    }

    public static func accent(_ text: String) -> Self {
        Self(viewModel: .init(text: text, style: .accent))
    }

    public static func selected(_ text: String) -> Self {
        Self(viewModel: .init(text: text, style: .selected))
    }

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 10
        static let topPadding: CGFloat = 3
        static let bottomPadding: CGFloat = 4
    }

    private let viewModel: ViewModel

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
