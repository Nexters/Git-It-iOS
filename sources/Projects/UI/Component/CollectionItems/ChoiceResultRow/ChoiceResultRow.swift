import DesignSystem
import SwiftUI

// MARK: - ChoiceResultRow

/// 채점 결과 행. 펼침 상태를 소유하지 않는다 — 이를 담는 패널이 `expanded` 집합으로 갖는다.
///
/// 크기 결정 방식은 `SizingMode.fill`이다. 세로만 규격 값(접힘 59 · 펼침 111)을 유지한다.
public struct ChoiceResultRow: View {

    // MARK: Lifecycle

    public init(
        judgement: Judgement,
        isExpanded: Bool,
        text: String,
        explanation: String,
        onTap: @escaping () -> Void,
    ) {
        self.judgement = judgement
        self.isExpanded = isExpanded
        self.text = text
        self.explanation = explanation
        self.onTap = onTap
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
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: LayoutToken.tightSpacing.cgFloatValue) {
                StyledText.body1(text, color: .grey100)
                    .lineLimit(1)

                if isExpanded {
                    StyledText.body3(explanation, color: .grey100)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constant.horizontalPadding)
            .frame(height: height, alignment: .top)
            .padding(.top, LayoutToken.compactSpacing.cgFloatValue)
            .designSystemBackground(judgement.backgroundColor)
            .designSystemCornerRadius(.large)
        }
        .buttonStyle(.pressOverlay)
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

    // MARK: Private

    private let judgement: Judgement
    private let isExpanded: Bool
    private let text: String
    private let explanation: String
    private let onTap: () -> Void

    private var height: CGFloat {
        isExpanded ? Constant.expandedHeight : Constant.collapsedHeight
    }

    private var accessibilityLabel: String {
        Self.accessibilityLabel(text: text, judgement: judgement)
    }

}

#Preview("Choice Result Row") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ChoiceResultRow(
            judgement: .correct,
            isExpanded: false,
            text: "State는 값 타입 소유에 쓴다",
            explanation: "뷰가 소유하는 단일 진실 원천입니다.",
        ) { }

        ChoiceResultRow(
            judgement: .incorrect,
            isExpanded: true,
            text: "Binding은 값을 소유한다",
            explanation: "Binding은 소유하지 않고 참조만 전달합니다.",
        ) { }
    }
    .padding(LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
