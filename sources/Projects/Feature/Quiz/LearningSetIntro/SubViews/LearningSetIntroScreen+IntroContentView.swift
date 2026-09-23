import DesignSystem
import SwiftUI
import UIComponent

extension LearningSetIntroScreen {
    struct IntroContentView: View {

        // MARK: Internal

        let isFailed: Bool
        let label: String
        let title: String
        let description: String

        var body: some View {
            if isFailed {
                failure
            } else {
                intro
            }
        }

        // MARK: Private

        private enum Constant {
            static let textSpacing: CGFloat = 8
            static let failureTextSpacing: CGFloat = 10
            static let descriptionTopPadding: CGFloat = 8
        }

        private var intro: some View {
            VStack(
                alignment: .leading,
                spacing: Constant.textSpacing,
            ) {
                StyledText(text: label)
                    .textStyle(.subtitle3)
                    .foregroundColorToken(.blue100)
                StyledText(text: title)
                    .textStyle(.subtitle1)
                StyledText(text: description)
                    .textStyle(.body2)
                    .foregroundColorToken(.grey400)
                    .padding(.top, Constant.descriptionTopPadding)
            }
            .designSystemScreenMargin()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .leading,
            )
        }

        private var failure: some View {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: Constant.failureTextSpacing) {
                    StyledText(text: LocalizedText.Quiz.introContentLoadFailureTitle)
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)
                    StyledText(text: LocalizedText.Quiz.introContentLoadFailureMessage)
                        .textStyle(.body2)
                        .foregroundColorToken(.grey400)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
            )
        }

    }
}
