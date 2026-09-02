import DesignSystem
import SwiftUI

// MARK: - ChoiceAnswerOption

/// 크기 결정 방식은 `SizingMode.fill`.
public struct ChoiceAnswerOption: View {

    // MARK: Lifecycle

    public init(
        text: String,
        state: State = .default,
        onTap: @escaping () -> Void = { },
    ) {
        self.text = text
        self.state = state
        self.onTap = onTap
    }

    // MARK: Public

    public enum State: Sendable, Equatable {
        case `default`
        case selected
        case correct
        case incorrect

        // MARK: Internal

        /// 기본은 테두리를 두지 않는다. 선택은 외곽 강조 테두리를 쓴다.
        var borderToken: BorderToken? {
            switch self {
            case .default:
                nil
            case .selected:
                .focus
            case .correct:
                BorderToken(name: "Correct", width: 1, colorToken: .correct)
            case .incorrect:
                BorderToken(name: "Incorrect", width: 1, colorToken: .incorrect)
            }
        }

        var borderColor: ColorToken {
            borderToken?.colorToken ?? .clear
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

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                StyledText.body1(text)
                    .lineLimit(2)

                Spacer(minLength: 0)

                if let symbol = state.symbol {
                    Image(systemName: symbol)
                        .designSystemForeground(state.borderColor)
                }
            }
            .padding(.horizontal, Constant.horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: Constant.minimumHeight, alignment: .leading)
            .designSystemBackground(.cardBackground)
            .designSystemCornerRadius(.large)
            .overlay {
                if let borderToken = state.borderToken {
                    RoundedRectangle(designSystem: .large)
                        .stroke(
                            Color(designSystem: borderToken.colorToken),
                            lineWidth: CGFloat(borderToken.width),
                        )
                }
            }
        }
        .buttonStyle(.pressOverlay)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(state == .selected ? .isSelected : [])
    }

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 16
        static let minimumHeight: CGFloat = 52
    }

    private let text: String
    private let state: State
    private let onTap: () -> Void

    private var accessibilityLabel: String {
        guard let suffix = state.accessibilitySuffix else {
            return text
        }
        return "\(text), \(suffix)"
    }

}

#Preview("Choice Answer Option") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ChoiceAnswerOption(text: "State", state: .default)
        ChoiceAnswerOption(text: "Binding", state: .selected)
        ChoiceAnswerOption(text: "ObservedObject", state: .correct)
        ChoiceAnswerOption(text: "EnvironmentObject", state: .incorrect)
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
