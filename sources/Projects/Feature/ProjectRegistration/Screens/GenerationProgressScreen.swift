import DesignSystem
import Foundation
import SwiftUI
import UIComponent

// MARK: - GenerationProgressScreen

struct GenerationProgressScreen: View {

    // MARK: Internal

    let onWaitAtHome: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Constant.topSpacerMinLength)

            ResourceAnimation(asset: .setCreationLoading)
                .frame(width: Constant.loadingGraphicSize, height: Constant.loadingGraphicSize)
                .mask(loadingGraphicFadeMask)
                .padding(.bottom, Constant.loadingGraphicBottomSpacing)

            VStack(spacing: Constant.textSetSpacing) {
                StyledText.subtitle1("학습세트를 만들고 있어요", alignment: .center)
                StyledText.body2("약 5분의 시간이 소요돼요", color: .grey400, alignment: .center)
            }

            checklist
                .padding(.vertical)
        }
        .designSystemScreenMargin()
        .safeAreaInset(edge: .bottom) {
            ActionButton.text("홈에서 기다리기", action: onWaitAtHome)
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
        }
        .designSystemBackground(backgroundGradient)
        .task { await runSimulatedProgress() }
    }

    // MARK: Private

    private enum Stage: CaseIterable {
        case repositoryInfo
        case codeStructureAnalysis
        case learningOutlineComposition
        case quizGeneration
        case verification

        // MARK: Internal

        var title: String {
            switch self {
            case .repositoryInfo: "프로젝트 정보 확인"
            case .codeStructureAnalysis: "코드 구조 분석"
            case .learningOutlineComposition: "학습 개념 구성"
            case .quizGeneration: "문제 생성"
            case .verification: "세트 검증"
            }
        }

        var progressRange: ClosedRange<Double> {
            switch self {
            case .repositoryInfo: 0...0.03
            case .codeStructureAnalysis: 0.03...0.38
            case .learningOutlineComposition: 0.38...0.55
            case .quizGeneration: 0.55...0.85
            case .verification: 0.85...0.99
            }
        }
    }

    private enum ChecklistStatus: Equatable {
        case done
        case active
        case pending

        // MARK: Internal

        @ViewBuilder
        var icon: some View {
            switch self {
            case .done: ResourceImage(asset: .icon(.statusCheck))
            case .active: ResourceAnimation(asset: .generalLoading, isLooping: true)
            case .pending: ResourceImage(asset: .icon(.statusLoadingDisabled))
            }
        }

        var accessibilityDescription: String {
            switch self {
            case .done: "완료"
            case .active: "진행 중"
            case .pending: "대기 중"
            }
        }
    }

    @State private var progress: Double = 0

    /// Figma `Gradient` 레이어(`2026:29389`)의 실제 `gradientTransform`을 읽으면(A, `use_figma`
    /// 2026-08-31) 색상 스톱 0%·100%가 도형 자체의 상하 경계가 아니라 도형 밖 y=549.4~1433.7(800pt
    /// 프레임 기준)에 위치한다 — 도형이 프레임보다 크고 아래로 이동해, 화면에는 0%~28% 구간만 보인다.
    /// 색은 그대로 두고 `start`/`end`만 이 값으로 프레임 밖까지 확장해야 같은 결과가 난다.
    private var backgroundGradient: GradientToken {
        GradientToken(
            name: "Gradient 2 · 생성 진행 화면",
            start: .init(x: 0.5, y: Constant.backgroundGradientStartY),
            end: .init(x: 0.5, y: Constant.backgroundGradientEndY),
            stops: GradientToken.gradient2.stops,
        )
    }

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

    private var checklist: some View {
        VStack(alignment: .leading, spacing: Constant.checklistRowSpacing) {
            ForEach(Stage.allCases, id: \.self) { stage in
                checklistRow(title: stage.title, status: status(for: stage))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("학습 세트 생성 진행 체크리스트")
    }

    private func checklistRow(
        title: String,
        status: ChecklistStatus,
    ) -> some View {
        HStack(spacing: LayoutToken.gutter.cgFloatValue) {
            status.icon
                .frame(width: Constant.checklistIconSize, height: Constant.checklistIconSize)
            StyledText.body2(title, color: status == .pending ? .grey400 : .grey100)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(status.accessibilityDescription)")
    }

    private func status(for stage: Stage) -> ChecklistStatus {
        if progress >= stage.progressRange.upperBound {
            .done
        } else if progress >= stage.progressRange.lowerBound {
            .active
        } else {
            .pending
        }
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

// MARK: GenerationProgressScreen.Constant

extension GenerationProgressScreen {
    private enum Constant {
        static let topSpacerMinLength: CGFloat = 97
        static let backgroundGradientStartY = 0.6868
        static let backgroundGradientEndY = 1.79211
        static let loadingGraphicSize: CGFloat = 200
        static let loadingGraphicFadeStart: CGFloat = 0.62
        static let loadingGraphicBottomSpacing: CGFloat = 25
        static let textSetSpacing: CGFloat = 16
        static let checklistTopPadding: CGFloat = 53
        static let checklistRowSpacing: CGFloat = 19
        static let checklistIconSize: CGFloat = 24
        static let bottomButtonPadding: CGFloat = 58
        static let simulatedDurationRange: ClosedRange<Double> = 180...300
        static let maxSimulatedProgress = 0.99
        static let simulatedProgressTickInterval = Duration.milliseconds(200)
    }
}
