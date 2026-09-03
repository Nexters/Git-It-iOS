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
        ScreenContainer { _ in
            screen
        }
    }

    // MARK: Private

    private var screen: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                style: .largeTitle,
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
                    StyledText
                        .headline2(
                            "\(store.correctChoiceCount) / \(store.choiceQuestionCount)",
                            alignment: .center,
                        )
                        .accessibilityLabel(scoreLabel)
                }

                StyledText.body2(Constant.message, color: .grey400, alignment: .center)
            }
            .designSystemScreenMargin()

            Spacer(minLength: 0)

            ActionButton.primary("확인", action: { send(.primaryActionTapped) })
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

}

// MARK: LearningCompletionScreen.Constant

extension LearningCompletionScreen {
    fileprivate enum Constant {
        static let contentSpacing: CGFloat = 16
        static let animationSize: CGFloat = 180
        static let bottomButtonPadding: CGFloat = 34
        static let message = "다음 세트에서 이어서 학습해 보세요."
    }
}
