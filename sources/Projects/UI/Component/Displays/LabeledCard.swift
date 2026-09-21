import DesignSystem
import SwiftUI

// MARK: - LabeledCard

public struct LabeledCard: View {

    // MARK: Lifecycle

    public init(
        label: String,
        text: String,
        style: Style,
    ) {
        self.label = label
        self.text = text
        self.style = style
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
        VStack(alignment: .leading, spacing: Constant.titleSpacing) {
            StyledText(text: label, style: .caption1, color: .blue100)
            StyledText(text: text, style: .body2, color: style.textColor)
        }
        .padding(Constant.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .designSystemBackground(style.background)
        .designSystemCornerRadius(.large)
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private enum Constant {
        static let titleSpacing: CGFloat = 8
        static let padding: CGFloat = 16
    }

    private let label: String
    private let text: String
    private let style: Style

}

#Preview("Labeled Card") {
    VStack(spacing: LayoutToken.gutter) {
        LabeledCard(label: "AI 해설", text: "State는 값 타입 소유에 씁니다.", style: .accent)
        LabeledCard(label: "나의 답안", text: "State는 값 타입을 소유할 때 사용합니다.", style: .neutral)
        LabeledCard(label: "AI의 답안", text: "State는 값 타입 소유에 씁니다.", style: .neutral)
    }
    .padding(LayoutToken.margin)
    .designSystemBackground(.grey700)
}
