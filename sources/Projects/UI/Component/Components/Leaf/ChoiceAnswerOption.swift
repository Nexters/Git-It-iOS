import DesignSystem
import SwiftUI

// MARK: - ChoiceAnswerOption

public struct ChoiceAnswerOption: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onTap: @escaping () -> Void = { },
    ) {
        self.viewModel = viewModel
        self.onTap = onTap
    }

    // MARK: Public

    public enum State: Sendable, Equatable {
        case `default`
        case selected
        case correct
        case incorrect

        // MARK: Internal

        var borderColor: ColorToken {
            switch self {
            case .default: .grey500
            case .selected: .blue100
            case .correct: .correct
            case .incorrect: .incorrect
            }
        }

        var symbol: String? {
            switch self {
            case .default,
                 .selected:
                nil
            case .correct:
                "checkmark.circle.fill"
            case .incorrect:
                "xmark.circle.fill"
            }
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

    public struct ViewModel: Sendable, Equatable {
        public init(
            text: String,
            state: State = .default,
        ) {
            self.text = text
            self.state = state
        }

        public let text: String
        public let state: State
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                StyledText.body1(viewModel.text)
                    .lineLimit(2)

                Spacer(minLength: 0)

                if let symbol = viewModel.state.symbol {
                    Image(systemName: symbol)
                        .designSystemForeground(viewModel.state.borderColor)
                }
            }
            .padding(.horizontal, Constant.horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: Constant.minimumHeight, alignment: .leading)
            .designSystemBackground(.cardBackground)
            .designSystemCornerRadius(.large)
            .overlay {
                RoundedRectangle(designSystem: .large)
                    .stroke(
                        Color(designSystem: viewModel.state.borderColor),
                        lineWidth: Constant.borderWidth,
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(viewModel.state == .selected ? .isSelected : [])
    }

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 16
        static let minimumHeight: CGFloat = 52
        static let borderWidth: CGFloat = 1
    }

    private let viewModel: ViewModel
    private let onTap: () -> Void

    private var accessibilityLabel: String {
        guard let suffix = viewModel.state.accessibilitySuffix else {
            return viewModel.text
        }
        return "\(viewModel.text), \(suffix)"
    }

}

#Preview("Choice Answer Option") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ChoiceAnswerOption(viewModel: .init(text: "State", state: .default))
        ChoiceAnswerOption(viewModel: .init(text: "Binding", state: .selected))
        ChoiceAnswerOption(viewModel: .init(text: "ObservedObject", state: .correct))
        ChoiceAnswerOption(viewModel: .init(text: "EnvironmentObject", state: .incorrect))
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
