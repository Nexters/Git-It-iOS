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
            ScreenHeader(
                style: .default,
                leading: .close,
                onLeadingTap: { send(.closeTapped) },
            )
            .designSystemScreenMargin()

            Spacer(minLength: 0)

            VStack(spacing: Constant.contentSpacing) {
                ResourceAnimation(asset: .complete, isLooping: false)
                    .frame(width: Constant.animationSize, height: Constant.animationSize)
                    .accessibilityHidden(true)

                StyledText.subtitle1("학습을 마쳤어요", alignment: .center)

                if let scoreLabel = store.scoreAccessibilityLabel {
                    scoreView
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(scoreLabel)
                }

                StyledText.body1(Constant.message, color: .grey400, alignment: .center)
            }
            .designSystemScreenMargin()

            Spacer(minLength: 0)

            ActionButton.primary("확인", action: { send(.primaryActionTapped) })
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

    private var scoreView: some View {
        HStack(spacing: Constant.scoreSpacing) {
            StyledText.subtitle1("\(store.correctChoiceCount)", color: .blue200)

            Rectangle()
                .fill(Color(designSystem: .grey400))
                .frame(width: Constant.scoreDividerWidth, height: Constant.scoreDividerHeight)

            StyledText.subtitle1("\(store.choiceQuestionCount)", color: .grey400)
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
