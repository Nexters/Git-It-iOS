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
            VStack(alignment: .trailing, spacing: LayoutToken.compactSpacing) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        StyledText.body1(placeholder, color: .grey400)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                        .contentMargins(.all, 0, for: .scrollContent)
                        .font(Font.designSystem(Constant.textStyle))
                        .designSystemLineSpacing(Constant.textStyle)
                        .focused(isFocused)
                        .designSystemForeground(.grey100)
                        .disabled(isDisabled)
                }
                .padding(Constant.textInset)
                .frame(minHeight: Constant.minimumHeight, maxHeight: Constant.maximumHeight, alignment: .top)
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
            static let textStyle = TextStyleToken.body1
            static let minimumHeight: CGFloat = 160
            static let maximumHeight: CGFloat = 240
            static let textInset: CGFloat = 16
        }

        private var borderToken: BorderToken {
            isFocused.wrappedValue ? .focus : .default
        }

    }
}
