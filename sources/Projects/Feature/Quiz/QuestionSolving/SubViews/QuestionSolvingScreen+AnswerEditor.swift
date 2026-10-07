import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct AnswerEditor: View {

        // MARK: Internal

        @Binding var text: String
        var isFocused: FocusState<Bool>.Binding

        let placeholder: String
        let characterLimit: Int
        let isDisabled: Bool

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
                        .focused(isFocused)
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

                StyledText.caption2("\(text.count) / \(characterLimit)", color: .grey400)
            }
        }

        // MARK: Private

        private enum Constant {
            static let minimumHeight: CGFloat = 160
            static let maximumHeight: CGFloat = 240
            static let textInset: CGFloat = 16
            static let editorHorizontalInset: CGFloat = 12
        }

        private var borderToken: BorderToken {
            isFocused.wrappedValue ? .focus : .default
        }

    }
}
