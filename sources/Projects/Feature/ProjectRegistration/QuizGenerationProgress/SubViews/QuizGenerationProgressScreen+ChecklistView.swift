import DesignSystem
import SwiftUI
import UIComponent

extension QuizGenerationProgressScreen {

    // MARK: Internal

    struct ChecklistView: View {

        // MARK: Internal

        let progress: Double

        var body: some View {
            VStack(alignment: .leading, spacing: Constant.rowSpacing) {
                ForEach(Stage.allCases, id: \.self) { stage in
                    checklistRow(title: stage.title, status: status(for: stage))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("학습 세트 생성 진행 체크리스트")
        }

        // MARK: Private

        private enum Constant {
            static let rowSpacing: CGFloat = 19
            static let itemSpacing: CGFloat = 14
            static let iconSize: CGFloat = 24
        }

        private func checklistRow(
            title: String,
            status: ChecklistStatus,
        ) -> some View {
            HStack(spacing: Constant.itemSpacing) {
                status.icon
                    .frame(
                        width: Constant.iconSize,
                        height: Constant.iconSize,
                    )
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

}
