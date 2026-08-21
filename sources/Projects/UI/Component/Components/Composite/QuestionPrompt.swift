import DesignSystem
import SwiftUI

// MARK: - QuestionPrompt

public struct QuestionPrompt: View {

    // MARK: Lifecycle

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            index: Int,
            total: Int,
            prompt: String,
        ) {
            self.index = index
            self.total = total
            self.prompt = prompt
        }

        public let index: Int
        public let total: Int
        public let prompt: String
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.compactSpacing.cgFloatValue) {
            StyledText.caption1("Q\(viewModel.index) / \(viewModel.total)", color: .blue100)
            StyledText.subtitle2(viewModel.prompt)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private let viewModel: ViewModel

}

#Preview("Question Prompt") {
    QuestionPrompt(
        viewModel: .init(
            index: 3,
            total: 10,
            prompt: "SwiftUI에서 State와 Binding의 차이를 설명하세요.",
        )
    )
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
