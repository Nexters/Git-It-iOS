import DesignSystem
import SwiftUI

// MARK: - ChoiceAnswerOption

public struct ChoiceAnswerOption: View {

    // MARK: Lifecycle

    public init(
        letter: String,
        text: String,
        state: State = .default,
        expansion: ExpansionControl = .fixed(isExpanded: true),
        onTap: @escaping () -> Void = { },
    ) {
        self.letter = letter
        self.text = text
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

    /// 선택지가 펼쳐지는 방식입니다. 답안을 고르는 동안에는 선택 여부만으로 펼침이
    /// 결정되는 `fixed` 형태를, 채점 결과를 확인할 때는 각 선택지를 독립적으로
    /// 열고 닫을 수 있는 `toggleable` 형태를 사용합니다.
    public enum ExpansionControl {
        case fixed(isExpanded: Bool)
        case toggleable(isExpanded: Bool, onToggleExpand: () -> Void)

        // MARK: Internal

        var isExpanded: Bool {
            switch self {
            case .fixed(let isExpanded):
                isExpanded
            case .toggleable(let isExpanded, _):
                isExpanded
            }
        }
    }

    public var body: some View {
        switch expansion {
        case .fixed(let isExpanded):
            card(isExpanded: isExpanded, reservesChevronSpace: false)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits(state == .selected ? .isSelected : [])

        case .toggleable(let isExpanded, let onToggleExpand):
            card(isExpanded: isExpanded, reservesChevronSpace: true)
                .overlay(alignment: .topTrailing) {
                    Button(action: onToggleExpand) {
                        ResourceImage(asset: .icon(isExpanded ? .chevronUp : .chevronDown), contentMode: .fit)
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
                .accessibilityAction(named: isExpanded ? "선택지 접기" : "선택지 펼치기", onToggleExpand)
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

    private let letter: String
    private let text: String
    private let state: State
    private let expansion: ExpansionControl
    private let onTap: () -> Void

    private var accessibilityLabel: String {
        guard let suffix = state.accessibilitySuffix else {
            return "\(letter), \(text)"
        }
        return "\(letter), \(text), \(suffix)"
    }

    private func card(
        isExpanded: Bool,
        reservesChevronSpace: Bool,
    ) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Constant.rowSpacing) {
                HStack {
                    StyledText.subtitle2(letter, color: state.letterColor)

                    Spacer(minLength: 0)

                    if reservesChevronSpace {
                        Color.clear.frame(width: Constant.chevronTapSize, height: Constant.chevronTapSize)
                    }
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

#Preview("Choice Answer Option") {
    VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
        ChoiceAnswerOption(letter: "A", text: "State", state: .default)
        ChoiceAnswerOption(letter: "B", text: "Binding", state: .selected, expansion: .fixed(isExpanded: true))
        ChoiceAnswerOption(
            letter: "C",
            text: "ObservedObject",
            state: .correct,
            expansion: .toggleable(isExpanded: true, onToggleExpand: { }),
        )
        ChoiceAnswerOption(
            letter: "D",
            text: "EnvironmentObject",
            state: .incorrect,
            expansion: .toggleable(isExpanded: false, onToggleExpand: { }),
        )
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
