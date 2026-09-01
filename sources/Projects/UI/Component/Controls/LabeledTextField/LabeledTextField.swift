import DesignSystem
import SwiftUI

// MARK: - LabeledTextField

public struct LabeledTextField: View {

    // MARK: Lifecycle

    public init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        supportingText: String? = nil,
        isError: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textInputAutocapitalization: TextInputAutocapitalization = .sentences,
        autocorrectionDisabled: Bool = false,
        accessibilityLabel: String? = nil,
        focus: FocusState<Bool>.Binding? = nil,
    ) {
        self.label = label
        self.placeholder = placeholder
        _text = text
        self.supportingText = supportingText
        self.isError = isError
        self.keyboardType = keyboardType
        self.textInputAutocapitalization = textInputAutocapitalization
        self.autocorrectionDisabled = autocorrectionDisabled
        self.accessibilityLabel = accessibilityLabel ?? label
        self.focus = focus
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Constant.trailingIconSpacing) {
                HStack(spacing: Constant.contentSpacing) {
                    StyledText.body2(label, color: accentColor)

                    SwiftUI.TextField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(Color(designSystem: .white30)),
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

            if let supportingText {
                StyledText.caption1(supportingText, color: isError ? .error : .grey300)
                    .padding(.leading, Constant.supportingTextLeadingPadding)
                    .padding(.top, Constant.supportingTextTopPadding)
            }
        }
    }

    // MARK: Internal

    @Binding var text: String

    // MARK: Private

    /// 호출부가 포커스를 관찰하지 않을 때 `focused(_:)`에 넘길 내부 상태입니다.
    @FocusState private var unboundFocus: Bool

    private let label: String
    private let placeholder: String
    private let supportingText: String?
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
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        LabeledTextField(label: "링크", placeholder: "https://github.com", text: .constant(""))
        LabeledTextField(label: "링크", placeholder: "https://github.com", text: .constant("https://github.com/gitit"))
        LabeledTextField(
            label: "링크",
            placeholder: "https://github.com",
            text: .constant("https://github.comakjshddhaag"),
            supportingText: "올바른 GitHub 레포지토리 링크를 입력해 주세요.",
            isError: true,
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
