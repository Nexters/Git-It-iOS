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
                leading: .close,
                onLeadingTap: { send(.closeTapped) },
            )
            .designSystemScreenMargin()

            Spacer(minLength: 0)

            VStack(spacing: Constant.contentSpacing) {
                ResourceAnimation(asset: .complete, isLooping: false)
                    .frame(width: Constant.animationSize, height: Constant.animationSize)
                    .accessibilityHidden(true)

                StyledText(text: "학습을 마쳤어요", style: .subtitle1, alignment: .center)

                if let scoreLabel = store.scoreAccessibilityLabel {
                    scoreView
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(scoreLabel)
                }

                StyledText(text: Constant.message, style: .body1, color: .grey400, alignment: .center)
            }
            .designSystemScreenMargin()

            Spacer(minLength: 0)

            FeedbackActionButton(title: "확인", style: .primary, action: { send(.primaryActionTapped) })
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

    private var scoreView: some View {
        HStack(spacing: Constant.scoreSpacing) {
            StyledText(text: "\(store.correctChoiceCount)", style: .subtitle1, color: .blue200)

            Rectangle()
                .fill(Color(designSystem: .grey400))
                .frame(width: Constant.scoreDividerWidth, height: Constant.scoreDividerHeight)

            StyledText(text: "\(store.choiceQuestionCount)", style: .subtitle1, color: .grey400)
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
