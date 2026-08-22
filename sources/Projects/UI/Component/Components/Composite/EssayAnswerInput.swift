import DesignSystem
import SwiftUI

// MARK: - EssayAnswerInput

public struct EssayAnswerInput: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        text: Binding<String>,
    ) {
        self.viewModel = viewModel
        _text = text
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            placeholder: String,
            characterLimit: Int = 2000,
            isDisabled: Bool = false,
        ) {
            self.placeholder = placeholder
            self.characterLimit = characterLimit
            self.isDisabled = isDisabled
        }

        public let placeholder: String
        public let characterLimit: Int
        public let isDisabled: Bool
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: LayoutToken.compactSpacing.cgFloatValue) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    StyledText.body1(viewModel.placeholder, color: .grey400)
                        .padding(.horizontal, Constant.textInset)
                        .padding(.vertical, Constant.textInset)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .designSystemForeground(.grey100)
                    .padding(.horizontal, Constant.editorHorizontalInset)
                    .disabled(viewModel.isDisabled)
                    .frame(maxHeight: Constant.maximumHeight)
            }
            .frame(minHeight: Constant.minimumHeight, maxHeight: Constant.maximumHeight)
            .designSystemBackground(.cardBackground)
            .designSystemCornerRadius(.small)

            StyledText.caption2(
                "\(text.count) / \(viewModel.characterLimit)",
                color: .grey400,
            )
        }
    }

    // MARK: Private

    private enum Constant {
        static let minimumHeight: CGFloat = 160
        static let maximumHeight: CGFloat = 240
        static let textInset: CGFloat = 16
        static let editorHorizontalInset: CGFloat = 12
    }

    private let viewModel: ViewModel

    @Binding private var text: String

}

#Preview("Essay Answer Input") {
    EssayAnswerInput(
        viewModel: .init(placeholder: "답안을 서술해주세요"),
        text: .constant(""),
    )
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
