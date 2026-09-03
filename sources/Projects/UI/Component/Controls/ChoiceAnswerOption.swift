import DesignSystem
import SwiftUI

// MARK: - ChoiceAnswerOption

public struct ChoiceAnswerOption: View {

    // MARK: Lifecycle

    public init(
        letter: String,
        text: String,
        state: State = .default,
        isExpanded: Bool = false,
        onTap: @escaping () -> Void = { },
    ) {
        self.letter = letter
        self.text = text
        self.state = state
        self.isExpanded = isExpanded
        self.onTap = onTap
    }

    // MARK: Public

    public enum State: Sendable, Equatable {
        case `default`
        case selected
        case correct
        case incorrect

        // MARK: Internal

        var fillToken: ColorToken? {
            switch self {
            case .default:
                nil
            case .selected,
                 .correct:
                .correct
            case .incorrect:
                .incorrect
            }
        }

        var letterColor: ColorToken {
            switch self {
            case .default:
                .blue200
            case .selected,
                 .correct,
                 .incorrect:
                .grey100
            }
        }

        var textColor: ColorToken {
            .grey100
        }

        var accessibilitySuffix: String? {
            switch self {
            case .default,
                 .selected:
                nil
            case .correct:
                "정답"
            case .incorrect:
                "오답"
            }
        }
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Constant.rowSpacing) {
                HStack {
                    StyledText.subtitle2(letter, color: state.letterColor)

                    Spacer(minLength: 0)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .designSystemForeground(state.letterColor)
                }

                if isExpanded {
                    StyledText.subtitle3(text, color: state.textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, Constant.horizontalPadding)
            .padding(.top, Constant.topPadding)
            .padding(.bottom, Constant.bottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                state.fillToken.map { Color(designSystem: $0) } ?? Color(designSystem: .grey600)
            )
            .designSystemCornerRadius(.large)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(state == .selected ? .isSelected : [])
    }

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 18
        static let topPadding: CGFloat = 14
        static let bottomPadding: CGFloat = 18
        static let rowSpacing: CGFloat = 4
    }

    private let letter: String
    private let text: String
    private let state: State
    private let isExpanded: Bool
    private let onTap: () -> Void

    private var accessibilityLabel: String {
        guard let suffix = state.accessibilitySuffix else {
            return "\(letter), \(text)"
        }
        return "\(letter), \(text), \(suffix)"
    }

}

#Preview("Choice Answer Option") {
    VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
        ChoiceAnswerOption(letter: "A", text: "State", state: .default)
        ChoiceAnswerOption(letter: "B", text: "Binding", state: .selected, isExpanded: true)
        ChoiceAnswerOption(letter: "C", text: "ObservedObject", state: .correct, isExpanded: true)
        ChoiceAnswerOption(letter: "D", text: "EnvironmentObject", state: .incorrect, isExpanded: true)
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
