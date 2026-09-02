import DesignSystem
import SwiftUI
import UIComponent

// MARK: - AnswerEditor

/// 서술형 답안 입력 Sub View.
///
/// 입력 문자열은 화면이 `Binding`으로 소유하고, 포커스처럼 자기 영역에만 의미가 있는
/// 상태는 이 Sub View가 소유한다. 크기 결정 방식은 채움이다.
struct AnswerEditor: View {

    // MARK: Internal

    @Binding var text: String

    var placeholder: String
    var characterLimit = Constant.defaultCharacterLimit
    var isDisabled = false

    var body: some View {
        VStack(alignment: .trailing, spacing: LayoutToken.compactSpacing.cgFloatValue) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    StyledText.body1(placeholder, color: .grey400)
                        .padding(Constant.textInset)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .focused($isFocused)
                    .designSystemForeground(.grey100)
                    .padding(.horizontal, Constant.editorHorizontalInset)
                    .disabled(isDisabled)
                    .frame(maxHeight: Constant.maximumHeight)
            }
            .frame(minHeight: Constant.minimumHeight, maxHeight: Constant.maximumHeight)
            .designSystemBackground(.cardBackground)
            .designSystemCornerRadius(.small)
            .overlay {
                RoundedRectangle(designSystem: .small)
                    .stroke(
                        Color(designSystem: borderToken.colorToken),
                        lineWidth: CGFloat(borderToken.width),
                    )
            }

            StyledText.caption2(
                "\(text.count) / \(characterLimit)",
                color: .grey400,
            )
        }
    }

    // MARK: Private

    @FocusState private var isFocused: Bool

    private var borderToken: BorderToken {
        isFocused ? .focus : .default
    }

}

extension AnswerEditor {
    enum Constant {
        static let defaultCharacterLimit = 400
        static let minimumHeight: CGFloat = 160
        static let maximumHeight: CGFloat = 240
        static let textInset: CGFloat = 16
        static let editorHorizontalInset: CGFloat = 12
    }
}

#Preview("Answer Editor") {
    AnswerEditor(
        text: .constant(""),
        placeholder: "답안을 서술해주세요",
    )
    .padding(LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
