import DesignSystem
import Foundation
import SwiftUI
import UIComponent

extension QuizGenerationProgressScreen {
    struct GeneratingView: View {

        // MARK: Internal

        let onWaitAtHome: () -> Void

        var body: some View {
            VStack(spacing: 0) {
                ResourceAnimation(asset: .setCreationLoading)
                    .frame(
                        width: Constant.loadingGraphicSize,
                        height: Constant.loadingGraphicSize,
                    )

                VStack(spacing: Constant.textSetSpacing) {
                    StyledText.subtitle1("학습세트를 만들고 있어요", alignment: .center)
                    StyledText.body2("약 5분의 시간이 소요돼요", color: .grey400, alignment: .center)
                }

                QuizGenerationProgressScreen.ChecklistView(progress: progress)
                    .padding(.top, Constant.checklistTopSpacing)
                Spacer()
            }
            .designSystemScreenMargin()
            .padding(.top, Constant.topSpacerMinLength)
            .safeAreaInset(edge: .bottom) {
                ActionButton.primaryText("홈에서 기다리기", action: onWaitAtHome)
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
