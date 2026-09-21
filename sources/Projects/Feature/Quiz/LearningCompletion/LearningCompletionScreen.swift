import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - LearningCompletionScreen

@ViewAction(for: LearningCompletionFeature.self)
struct LearningCompletionScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<LearningCompletionFeature>

    var body: some View {
        ScreenContainer {
            screen
        }
    }

    // MARK: Private

    private var screen: some View {
        VStack(spacing: 0) {
            ScreenControlBar(
                displayModel: .init(leading: .close),
                onLeadingTap: { send(.closeTapped) },
            )
            .designSystemScreenMargin()

            Spacer(minLength: 0)

            VStack(spacing: Constant.contentSpacing) {
                ResourceAnimation(asset: .complete, stateModel: .init(isLooping: false))
                    .frame(width: Constant.animationSize, height: Constant.animationSize)
                    .accessibilityHidden(true)

                StyledText(text: "학습을 마쳤어요")
                    .textStyle(.subtitle1)
                    .multilineTextAlignment(.center)

                if let scoreLabel = store.scoreAccessibilityLabel {
                    scoreView
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(scoreLabel)
                }

                StyledText(text: Constant.message)
                    .foregroundColorToken(.grey400)
                    .multilineTextAlignment(.center)
            }
            .designSystemScreenMargin()

            Spacer(minLength: 0)

            FeedbackActionButton(title: "확인", action: { send(.primaryActionTapped) })
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

    private var scoreView: some View {
        HStack(spacing: Constant.scoreSpacing) {
            StyledText(text: "\(store.correctChoiceCount)")
                .textStyle(.subtitle1)
                .foregroundColorToken(.blue200)

            Rectangle()
                .fill(Color(designSystem: .grey400))
                .frame(width: Constant.scoreDividerWidth, height: Constant.scoreDividerHeight)

            StyledText(text: "\(store.choiceQuestionCount)")
                .textStyle(.subtitle1)
                .foregroundColorToken(.grey400)
        }
    }

}

// MARK: LearningCompletionScreen.Constant

extension LearningCompletionScreen {
    fileprivate enum Constant {
        static let contentSpacing: CGFloat = 16
        static let animationSize: CGFloat = 200
        static let scoreSpacing: CGFloat = 5
        static let scoreDividerWidth: CGFloat = 1
        static let scoreDividerHeight: CGFloat = 22
        static let bottomButtonPadding: CGFloat = 24
        static let message = "다음 세트에서 이어서 학습해 보세요."
    }
}
