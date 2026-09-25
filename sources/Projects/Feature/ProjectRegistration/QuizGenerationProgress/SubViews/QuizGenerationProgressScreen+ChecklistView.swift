import DesignSystem
import SwiftUI
import UIComponent

extension QuizGenerationProgressScreen {

    // MARK: Internal

    struct ChecklistView: View {

        // MARK: Internal

        let progress: Double

        var body: some View {
            VStack(
                alignment: .leading,
                spacing: Constant.rowSpacing,
            ) {
                ForEach(
                    Stage.allCases,
                    id: \.self,
                ) { stage in
                    checklistRow(
                        title: stage.title,
                        status: status(for: stage),
                    )
                }
            }
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
                StyledText(text: title)
                    .textStyle(.body2)
                    .foregroundColorToken(status == .pending ? .grey400 : .grey100)
                    .lineLimit(1)
            }
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
            case .repositoryInfo: LocalizedText.ProjectRegistration.Checklist.RepositoryInfo.title
            case .codeStructureAnalysis: LocalizedText.ProjectRegistration.Checklist.CodeStructureAnalysis.title
            case .learningOutlineComposition: LocalizedText.ProjectRegistration.Checklist.LearningOutlineComposition.title
            case .quizGeneration: LocalizedText.ProjectRegistration.Checklist.QuizGeneration.title
            case .verification: LocalizedText.ProjectRegistration.Checklist.Verification.title
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
            case .active: ResourceAnimation(asset: .generalLoading)
            case .pending: ResourceImage(asset: .icon(.statusLoadingDisabled))
            }
        }
    }

}
