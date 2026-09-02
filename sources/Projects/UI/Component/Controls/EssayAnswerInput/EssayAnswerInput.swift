import DesignSystem
import SwiftUI

// MARK: - EssayAnswerInput

/// 크기 결정 방식은 `SizingMode.fill`.
public struct EssayAnswerInput: View {

    // MARK: Lifecycle

    public init(
        placeholder: String,
        text: Binding<String>,
        characterLimit: Int = 400,
        isDisabled: Bool = false,
    ) {
        self.placeholder = placeholder
        _text = text
        self.characterLimit = characterLimit
        self.isDisabled = isDisabled
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .trailing, spacing: LayoutToken.compactSpacing.cgFloatValue) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    StyledText.body1(placeholder, color: .grey400)
                        .padding(.horizontal, Constant.textInset)
                        .padding(.vertical, Constant.textInset)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .designSystemForeground(.grey100)
                    .padding(.horizontal, Constant.editorHorizontalInset)
                    .disabled(isDisabled)
                    .frame(maxHeight: Constant.maximumHeight)
            }
            .frame(minHeight: Constant.minimumHeight, maxHeight: Constant.maximumHeight)
            .designSystemBackground(.cardBackground)
            .designSystemCornerRadius(.small)

            StyledText.caption2(
                "\(text.count) / \(characterLimit)",
                color: .grey400,
            )
        }
    }

    // MARK: Private

    @Binding private var text: String

    private let placeholder: String
    private let characterLimit: Int
    private let isDisabled: Bool

}

#Preview("Essay Answer Input") {
    EssayAnswerInput(
        placeholder: "답안을 서술해주세요",
        text: .constant(""),
    )
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
