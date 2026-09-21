import DesignSystem
import SwiftUI

// MARK: - ChoiceAnswerOption

public struct ChoiceAnswerOption: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        state: State = .default,
        expansion: ExpansionControl = .fixed(isExpanded: true),
        onTap: @escaping () -> Void = { },
    ) {
        self.displayModel = displayModel
        self.state = state
        self.expansion = expansion
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
            case .default,
                 .selected:
                nil
            case .correct:
                .correct
            case .incorrect:
                .incorrect
            }
        }

        var borderToken: BorderToken {
            switch self {
            case .selected:
                .focus
            case .default,
                 .correct,
                 .incorrect:
                .default
            }
        }

        var letterColor: ColorToken {
            switch self {
            case .default,
                 .selected:
                .blue200
            case .correct,
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

    public enum ExpansionControl {
        case fixed(isExpanded: Bool)
        case toggleable(isExpanded: Binding<Bool>)

        // MARK: Internal

        var isExpanded: Bool {
            switch self {
            case .fixed(let isExpanded):
                isExpanded
            case .toggleable(let isExpanded):
                isExpanded.wrappedValue
            }
        }

        func toggle() {
            guard case .toggleable(let isExpanded) = self else { return }
            isExpanded.wrappedValue.toggle()
        }
    }

    public var body: some View {
        switch expansion {
        case .fixed(let isExpanded):
            card(isExpanded: isExpanded, reservesChevronSpace: false)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits(state == .selected ? .isSelected : [])

        case .toggleable(let isExpanded):
            card(isExpanded: isExpanded.wrappedValue, reservesChevronSpace: true)
                .overlay(alignment: .topTrailing) {
                    Button(action: { expansion.toggle() }) {
                        ResourceImage(asset: .icon(isExpanded.wrappedValue ? .chevronUp : .chevronDown), contentMode: .fit)
                            .designSystemForeground(.blue100)
                            .frame(width: Constant.chevronIconSize, height: Constant.chevronIconSize)
                            .frame(width: Constant.chevronTapSize, height: Constant.chevronTapSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHidden(true)
                    .padding(.trailing, Constant.horizontalPadding)
                    .padding(.top, Constant.topPadding)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits(state == .selected ? .isSelected : [])
                .accessibilityAction(named: isExpanded.wrappedValue ? "선택지 접기" : "선택지 펼치기") { expansion.toggle() }
        }
    }

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 18
        static let topPadding: CGFloat = 14
        static let bottomPadding: CGFloat = 18
        static let rowSpacing: CGFloat = 4
        static let chevronIconSize: CGFloat = 16
        static let chevronTapSize: CGFloat = 36
    }

    private let displayModel: DisplayModel
    private let state: State
    private let expansion: ExpansionControl
    private let onTap: () -> Void

    private var accessibilityLabel: String {
        guard let suffix = state.accessibilitySuffix else {
            return "\(displayModel.letter), \(displayModel.text)"
        }
        return "\(displayModel.letter), \(displayModel.text), \(suffix)"
    }

    private func card(
        isExpanded: Bool,
        reservesChevronSpace: Bool,
    ) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Constant.rowSpacing) {
                HStack {
                    StyledText(text: displayModel.letter)
                        .textStyle(.subtitle2)
                        .foregroundColorToken(state.letterColor)

                    Spacer(minLength: 0)

                    if reservesChevronSpace {
                        Color.clear.frame(width: Constant.chevronTapSize, height: Constant.chevronTapSize)
                    }
                }

                if isExpanded {
                    StyledText(text: displayModel.text)
                        .textStyle(.subtitle3)
                        .foregroundColorToken(state.textColor)
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
            .overlay {
                RoundedRectangle(designSystem: .large)
                    .stroke(
                        Color(designSystem: state.borderToken.colorToken),
                        lineWidth: CGFloat(state.borderToken.width),
                    )
            }
        }
        .buttonStyle(.plain)
    }

}

// MARK: ChoiceAnswerOption.DisplayModel

extension ChoiceAnswerOption {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            letter: String,
            text: String,
        ) {
            self.letter = letter
            self.text = text
        }

        public let letter: String
        public let text: String
    }
}

#Preview("Choice Answer Option") {
    VStack(spacing: LayoutToken.compactSpacing) {
        ChoiceAnswerOption(displayModel: .init(letter: "A", text: "State"), state: .default)
        ChoiceAnswerOption(
            displayModel: .init(letter: "B", text: "Binding"),
            state: .selected,
            expansion: .fixed(isExpanded: true),
        )
        ChoiceAnswerOption(
            displayModel: .init(letter: "C", text: "ObservedObject"),
            state: .correct,
            expansion: .toggleable(isExpanded: .constant(true)),
        )
        ChoiceAnswerOption(
            displayModel: .init(letter: "D", text: "EnvironmentObject"),
            state: .incorrect,
            expansion: .toggleable(isExpanded: .constant(false)),
        )
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
