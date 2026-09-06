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
                Spacer(minLength: Constant.topSpacerMinLength)

                ResourceAnimation(asset: .setCreationLoading)
                    .frame(
                        width: Constant.loadingGraphicSize,
                        height: Constant.loadingGraphicSize,
                    )
                    .mask(loadingGraphicFadeMask)
                    .padding(.bottom, Constant.loadingGraphicBottomSpacing)

                VStack(spacing: Constant.textSetSpacing) {
                    StyledText.subtitle1("학습세트를 만들고 있어요", alignment: .center)
                    StyledText.body2("약 5분의 시간이 소요돼요", color: .grey400, alignment: .center)
                }

                QuizGenerationProgressScreen.ChecklistView(progress: progress)
                    .padding(.top, Constant.checklistTopSpacing)
            }
            .designSystemScreenMargin()
            .safeAreaInset(edge: .bottom) {
                ActionButton.primaryText("홈에서 기다리기", action: onWaitAtHome)
                    .designSystemScreenMargin()
                    .padding(.bottom, Constant.bottomButtonPadding)
            }
            .designSystemBackground(Constant.backgroundGradient)
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

            static let backgroundGradient = GradientToken(
                name: "Gradient 2 · 생성 진행 화면",
                start: .init(x: 0.5, y: 0.6868),
                end: .init(x: 0.5, y: 1.79211),
                stops: GradientToken.gradient2.stops,
            )
        }

        @State private var progress: Double = 0

        private var loadingGraphicFadeMask: some View {
            RadialGradient(
                stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: Constant.loadingGraphicFadeStart),
                    .init(color: .clear, location: 1),
                ],
                center: .center,
                startRadius: 0,
                endRadius: Constant.loadingGraphicSize / 2,
            )
        }

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
