import DesignSystem
import SwiftUI

// MARK: - LabeledTextField

public struct LabeledTextField: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        text: Binding<String>,
        isError: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textInputAutocapitalization: TextInputAutocapitalization = .sentences,
        autocorrectionDisabled: Bool = false,
        accessibilityLabel: String? = nil,
        focus: FocusState<Bool>.Binding? = nil,
    ) {
        self.displayModel = displayModel
        _text = text
        self.isError = isError
        self.keyboardType = keyboardType
        self.textInputAutocapitalization = textInputAutocapitalization
        self.autocorrectionDisabled = autocorrectionDisabled
        self.accessibilityLabel = accessibilityLabel ?? displayModel.label
        self.focus = focus
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Constant.trailingIconSpacing) {
                HStack(spacing: Constant.contentSpacing) {
                    StyledText(text: displayModel.label)
                        .textStyle(.body2)
                        .foregroundColorToken(accentColor)

                    SwiftUI.TextField(
                        "",
                        text: $text,
                        prompt: Text(displayModel.placeholder).foregroundStyle(Color(designSystem: .white30)),
                    )
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(textInputAutocapitalization)
                    .autocorrectionDisabled(autocorrectionDisabled)
                    .designSystemForeground(.grey100)
                    .accessibilityLabel(accessibilityLabel)
                    .focused(focus ?? $unboundFocus)
                }

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        ResourceImage(asset: .icon(.cancel), contentMode: .fit)
                            .frame(width: Constant.clearIconSize, height: Constant.clearIconSize)
                    }
                    .buttonStyle(.plain)
                    .frame(width: Constant.clearButtonTouchSize, height: Constant.clearButtonTouchSize)
                    .accessibilityLabel("입력 지우기")
                }
            }
            .frame(height: Constant.fieldHeight)

            Rectangle()
                .fill(Color(designSystem: accentColor))
                .frame(height: Constant.underlineHeight)

            if let supportingText = displayModel.supportingText {
                StyledText(text: supportingText)
                    .textStyle(.caption1)
                    .foregroundColorToken(isError ? .error : .grey300)
                    .padding(.leading, Constant.supportingTextLeadingPadding)
                    .padding(.top, Constant.supportingTextTopPadding)
            }
        }
    }

    // MARK: Internal

    @Binding var text: String

    // MARK: Private

    @FocusState private var unboundFocus: Bool

    private let displayModel: DisplayModel
    private let isError: Bool
    private let keyboardType: UIKeyboardType
    private let textInputAutocapitalization: TextInputAutocapitalization
    private let autocorrectionDisabled: Bool
    private let accessibilityLabel: String
    private let focus: FocusState<Bool>.Binding?

    private var accentColor: ColorToken {
        isError ? .error : .blue100
    }

}

// MARK: LabeledTextField.DisplayModel

extension LabeledTextField {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            label: String,
            placeholder: String,
            supportingText: String? = nil,
        ) {
            self.label = label
            self.placeholder = placeholder
            self.supportingText = supportingText
        }

        public let label: String
        public let placeholder: String
        public let supportingText: String?
    }
}

// MARK: LabeledTextField.Constant

extension LabeledTextField {
    private enum Constant {
        static let fieldHeight: CGFloat = 56
        static let underlineHeight: CGFloat = 1
        static let contentSpacing: CGFloat = 16
        static let trailingIconSpacing: CGFloat = 4
        static let clearIconSize: CGFloat = 20
        static let clearButtonTouchSize: CGFloat = 44
        static let supportingTextLeadingPadding: CGFloat = 47
        static let supportingTextTopPadding: CGFloat = 4
    }
}

#Preview("LabeledTextField") {
    VStack(spacing: LayoutToken.margin) {
        LabeledTextField(displayModel: .init(label: "링크", placeholder: "https://github.com"), text: .constant(""))
        LabeledTextField(
            displayModel: .init(label: "링크", placeholder: "https://github.com"),
            text: .constant("https://github.com/gitit"),
        )
        LabeledTextField(
            displayModel: .init(
                label: "링크",
                placeholder: "https://github.com",
                supportingText: "올바른 GitHub 레포지토리 링크를 입력해 주세요.",
            ),
            text: .constant("https://github.comakjshddhaag"),
            isError: true,
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
