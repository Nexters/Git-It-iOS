import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - QuizGenerationConfirmationScreen

@ViewAction(for: QuizGenerationConfirmationFeature.self)
struct QuizGenerationConfirmationScreen: View {

    @Bindable var store: StoreOf<QuizGenerationConfirmationFeature>

    var body: some View {
        VStack(spacing: 0) {
            ScreenControlBar(onLeadingTap: { send(.backTapped) })
                .designSystemScreenMargin()

            Spacer(minLength: 0)

            VStack(spacing: Constant.textSetSpacing) {
                StyledText(text: LocalizedText.ProjectRegistration.quizGenerationConfirmationTitle)
                    .textStyle(.subtitle1)
                    .multilineTextAlignment(.center)
                StyledText(text: LocalizedText.ProjectRegistration.quizGenerationConfirmationDurationMessage)
                    .textStyle(.body2)
                    .foregroundColorToken(.grey400)
                    .multilineTextAlignment(.center)
            }
            .designSystemScreenMargin()

            Spacer(minLength: 0)

            FeedbackActionButton(
                title: LocalizedText.ProjectRegistration.quizGenerationConfirmationStartButtonTitle,
                action: { send(.startTapped) },
            )
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

}

// MARK: QuizGenerationConfirmationScreen.Constant

extension QuizGenerationConfirmationScreen {
    fileprivate enum Constant {
        static let textSetSpacing: CGFloat = 16
        static let bottomButtonPadding: CGFloat = 24
    }
}
