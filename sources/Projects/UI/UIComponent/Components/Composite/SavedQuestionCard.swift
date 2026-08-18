import DesignSystem
import SwiftUI

public struct SavedQuestionCard: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onActionTap: @escaping () -> Void = { },
    ) {
        self.viewModel = viewModel
        self.onActionTap = onActionTap
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            metadata: String,
            prompt: String,
            actionTitle: String,
        ) {
            self.metadata = metadata
            self.prompt = prompt
            self.actionTitle = actionTitle
        }

        public let metadata: String
        public let prompt: String
        public let actionTitle: String
    }

    public var body: some View {
        VStack(alignment: .leading) {
            StyledText.caption1(viewModel.metadata, color: .grey300)
                .padding(.top, 14)
            StyledText.subtitle3(viewModel.prompt)
                .padding(.top, 10)
            HStack {
                Image( "ic-bookmark-filled", bundle: .module)
                    .designSystemForeground(.brandAccent)
                    .padding(.horizontal, 10)
                Spacer()
                Button(action: onActionTap) {
                    StyledText.body2(viewModel.actionTitle, color: .grey700, alignment: .center)
                }.frame(width: 84, height: 36)
                    .designSystemBackground(.blue100)
                    .designSystemCornerRadius(.small)
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal, Constant.contentPadding)
        .background(
            Color(designSystem: .cardBackground),
            in: RoundedRectangle(designSystem: .large),
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private enum Constant {
        static let contentPadding: CGFloat = 18
    }

    private let viewModel: ViewModel
    private let onActionTap: () -> Void

}

#Preview("Saved Question Card") {
    SavedQuestionCard(
        viewModel: .init(
            metadata: "Now in Android · Set 2 · 문제 1",
            prompt: "BlueprintSetupState 클래스는 어떤 목적을 가진 객체인가?",
            actionTitle: "문제풀기",
        )
    )
    .frame(width: 350)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
