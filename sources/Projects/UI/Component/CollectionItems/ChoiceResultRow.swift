import DesignSystem
import SwiftUI

// MARK: - ChoiceResultRow

public struct ChoiceResultRow: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        judgement: Judgement,
        isExpanded: Binding<Bool>,
    ) {
        self.displayModel = displayModel
        self.judgement = judgement
        _isExpanded = isExpanded
    }

    // MARK: Public

    public enum Judgement: Sendable, Equatable {
        case correct
        case incorrect

        // MARK: Internal

        var backgroundColor: ColorToken {
            switch self {
            case .correct:
                .correct
            case .incorrect:
                .incorrect
            }
        }

        var accessibilitySuffix: String {
            switch self {
            case .correct:
                "정답"
            case .incorrect:
                "오답"
            }
        }
    }

    public var body: some View {
        Button(action: toggle) {
            VStack(alignment: .leading, spacing: LayoutToken.tightSpacing) {
                StyledText(text: displayModel.text)
                    .lineLimit(1)

                if isExpanded {
                    StyledText(text: displayModel.explanation)
                        .textStyle(.body3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constant.horizontalPadding)
            .frame(height: height, alignment: .top)
            .padding(.top, LayoutToken.compactSpacing)
            .designSystemBackground(judgement.backgroundColor)
            .designSystemCornerRadius(.large)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isExpanded ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Internal

    static func accessibilityLabel(
        text: String,
        judgement: Judgement,
    ) -> String {
        "\(text), \(judgement.accessibilitySuffix)"
    }

    func toggle() {
        isExpanded.toggle()
    }

    // MARK: Private

    private enum Constant {
        static let collapsedHeight: CGFloat = 59
        static let expandedHeight: CGFloat = 111
        static let horizontalPadding: CGFloat = 16
    }

    @Binding private var isExpanded: Bool

    private let displayModel: DisplayModel
    private let judgement: Judgement

    private var height: CGFloat {
        isExpanded ? Constant.expandedHeight : Constant.collapsedHeight
    }

    private var accessibilityLabel: String {
        Self.accessibilityLabel(text: displayModel.text, judgement: judgement)
    }

}

// MARK: ChoiceResultRow.DisplayModel

extension ChoiceResultRow {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            text: String,
            explanation: String,
        ) {
            self.text = text
            self.explanation = explanation
        }

        public let text: String
        public let explanation: String
    }
}

#Preview("Choice Result Row") {
    VStack(spacing: LayoutToken.gutter) {
        ChoiceResultRow(
            displayModel: .init(text: "State는 값 타입 소유에 쓴다", explanation: "뷰가 소유하는 단일 진실 원천입니다."),
            judgement: .correct,
            isExpanded: .constant(false),
        )

        ChoiceResultRow(
            displayModel: .init(text: "Binding은 값을 소유한다", explanation: "Binding은 소유하지 않고 참조만 전달합니다."),
            judgement: .incorrect,
            isExpanded: .constant(true),
        )
    }
    .padding(LayoutToken.margin)
    .designSystemBackground(.grey700)
}
