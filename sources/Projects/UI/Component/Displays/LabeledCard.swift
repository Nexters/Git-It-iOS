import DesignSystem
import SwiftUI

// MARK: - LabeledCard

public struct LabeledCard: View {

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: Constant.titleSpacing) {
            StyledText.caption1(label, color: .blue100)
            StyledText.body2(text, color: style.textColor)
        }
        .padding(Constant.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .designSystemBackground(style.background)
        .designSystemCornerRadius(.large)
        .accessibilityElement(children: .combine)
    }

    public static func accent(
        label: String,
        text: String,
    ) -> Self {
        Self(label: label, text: text, style: .accent)
    }

    public static func neutral(
        label: String,
        text: String,
    ) -> Self {
        Self(label: label, text: text, style: .neutral)
    }

    // MARK: Private

    private enum Style: Sendable, Equatable {
        case accent
        case neutral

        // MARK: Internal

        var background: SemanticColorToken {
            switch self {
            case .accent: .accentSurface
            case .neutral: .cardBackground
            }
        }

        var textColor: ColorToken {
            switch self {
            case .accent: .grey100
            case .neutral: .grey300
            }
        }
    }

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
        LabeledCard.accent(label: "AI 해설", text: "State는 값 타입 소유에 씁니다.")
        LabeledCard.neutral(label: "나의 답안", text: "State는 값 타입을 소유할 때 사용합니다.")
        LabeledCard.neutral(label: "AI의 답안", text: "State는 값 타입 소유에 씁니다.")
    }
    .padding(LayoutToken.margin)
    .designSystemBackground(.grey700)
}
