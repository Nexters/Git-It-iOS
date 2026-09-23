import DesignSystem
import Foundation
import SwiftUI
import UIComponent

extension QuizGenerationProgressScreen {
    struct GeneratingView: View {

        // MARK: Internal

        let onWaitAtHome: () -> Void

        var body: some View {
            VStack(
                alignment: .leading,
                spacing: 0,
            ) {
                ResourceAnimation(asset: .setCreationLoading)
                    .frame(
                        width: Constant.loadingGraphicSize,
                        height: Constant.loadingGraphicSize,
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 30)

                VStack(spacing: Constant.textSetSpacing) {
                    StyledText(text: LocalizedText.ProjectRegistration.quizGenerationProgressTitle)
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)
                    StyledText(text: LocalizedText.ProjectRegistration.quizGenerationProgressDurationMessage)
                        .textStyle(.body2)
                        .foregroundColorToken(.grey400)
                        .multilineTextAlignment(.center)
                }

                QuizGenerationProgressScreen.ChecklistView(progress: progress)
                    .padding(.top, Constant.checklistTopSpacing)
            }
            .frame(maxHeight: .infinity)
            .padding(.vertical)
            .designSystemScreenMargin()
            .safeAreaInset(edge: .bottom) {
                FeedbackActionButton(
                    title: LocalizedText.ProjectRegistration.quizGenerationProgressWaitAtHomeButtonTitle,
                    action: onWaitAtHome,
                )
                .style(.primaryText)
                .designSystemScreenMargin()
                .padding(.vertical, Constant.bottomButtonPadding)
            }
            .designSystemBackground(.backgroundGradient)
            .task { await runSimulatedProgress() }
        }

        // MARK: Private

        private enum Constant {
            static let topSpacerMinLength: CGFloat = 97
            static let loadingGraphicSize: CGFloat = 200
            static let loadingGraphicFadeStart: CGFloat = 0.62
            static let loadingGraphicBottomSpacing: CGFloat = 25
            static let textSetSpacing: CGFloat = 16
            static let checklistTopSpacing: CGFloat = 53
            static let bottomButtonPadding: CGFloat = 24
            static let simulatedDurationRange: ClosedRange<Double> = 180...300
            static let maxSimulatedProgress = 0.98
            static let simulatedProgressTickInterval = Duration.milliseconds(200)
        }

        @State private var progress: Double = 0

        private func runSimulatedProgress() async {
            let totalDuration = Double.random(in: Constant.simulatedDurationRange)
            let startDate = Date()
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startDate)
                progress = min(elapsed / totalDuration, Constant.maxSimulatedProgress)
                if progress >= Constant.maxSimulatedProgress {
                    break
                }
                try? await Task.sleep(for: Constant.simulatedProgressTickInterval)
            }
        }

    }
}
