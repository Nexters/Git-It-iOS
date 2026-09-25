import DesignSystem
import SwiftUI
import UIComponent

extension QuizGenerationProgressScreen {
    struct GenerationReminderSheet: View {

        // MARK: Internal

        let onAccept: () -> Void
        let onDecline: () -> Void

        var body: some View {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                SheetSurface {
                    VStack(spacing: Constant.contentSpacing) {
                        ResourceAnimation(asset: .notification)
                            .frame(
                                width: Constant.bellSize,
                                height: Constant.bellSize,
                            )

                        VStack(spacing: Constant.textSetSpacing) {
                            StyledText(text: LocalizedText.ProjectRegistration.GenerationReminderSheet.title)
                                .textStyle(.subtitle1)
                                .multilineTextAlignment(.center)
                            StyledText(text: LocalizedText.ProjectRegistration.GenerationReminderSheet.message)
                                .textStyle(.caption1)
                                .foregroundColorToken(.grey400)
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: LayoutToken.compactSpacing) {
                            FeedbackActionButton(
                                title: LocalizedText.ProjectRegistration.GenerationReminderSheet.Enable.buttonTitle,
                                action: onAccept,
                            )

                            FeedbackActionButton(
                                title: LocalizedText.ProjectRegistration.GenerationReminderSheet.Dismiss.buttonTitle,
                                action: onDecline,
                            )
                            .style(.text)
                            .size(.small)
                        }
                    }
                    .padding(.top, Constant.contentTopPadding)
                }
            }
            .designSystemBackground(.clear)
            .presentationBackground(.clear)
        }

        // MARK: Private

        private enum Constant {
            static let contentSpacing: CGFloat = 31
            static let textSetSpacing: CGFloat = 8
            static let bellSize: CGFloat = 120
            static let contentTopPadding: CGFloat = 21
        }

    }
}
