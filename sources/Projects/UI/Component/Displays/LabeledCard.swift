import DesignSystem
import SwiftUI

// MARK: - LabeledCard

public struct LabeledCard: View {

    // MARK: Lifecycle

    public init(displayModel: DisplayModel) {
        self.displayModel = displayModel
    }

    // MARK: Public

    public enum Style: Sendable, Equatable {
        case accent
        case neutral

        // MARK: Internal

        var background: ColorToken {
            switch self {
            case .accent: .blue500
            case .neutral: .grey600
            }
        }

        var textColor: ColorToken {
            switch self {
            case .accent: .grey100
            case .neutral: .grey300
            }
        }
    }

    public var body: some View {
        VStack(
            alignment: .leading,
            spacing: Constant.titleSpacing,
        ) {
            StyledText(text: displayModel.label)
                .textStyle(.caption1)
                .foregroundColorToken(.blue100)
            StyledText(text: displayModel.text)
                .textStyle(.body2)
                .foregroundColorToken(style.textColor)
        }
        .padding(Constant.padding)
        .frame(
            maxWidth: .infinity,
            alignment: .leading,
        )
        .designSystemBackground(style.background)
        .designSystemCornerRadius(.large)
    }

    // MARK: Private

    private enum Constant {
        static let titleSpacing: CGFloat = 8
        static let padding: CGFloat = 16
    }

    private let displayModel: DisplayModel
    private var style = Style.neutral

}

// MARK: LabeledCard.DisplayModel

extension LabeledCard {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            label: String,
            text: String,
        ) {
            self.label = label
            self.text = text
        }

        public let label: String
        public let text: String
    }
}

// MARK: StyleConfigurable

extension LabeledCard: StyleConfigurable {
    public func style(_ style: Style) -> Self {
        var copy = self
        copy.style = style
        return copy
    }
}

#Preview("Labeled Card") {
    VStack(spacing: LayoutToken.gutter) {
        LabeledCard(displayModel: .init(
            label: "AI 해설",
            text: "State는 값 타입 소유에 씁니다.",
        ))
        .style(.accent)
        LabeledCard(displayModel: .init(
            label: "나의 답안",
            text: "State는 값 타입을 소유할 때 사용합니다.",
        ))
        LabeledCard(displayModel: .init(
            label: "AI의 답안",
            text: "State는 값 타입 소유에 씁니다.",
        ))
    }
    .padding(LayoutToken.margin)
    .designSystemBackground(.grey700)
}
