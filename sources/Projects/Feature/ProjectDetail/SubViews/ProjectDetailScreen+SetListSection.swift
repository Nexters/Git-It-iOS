import DesignSystem
import SwiftUI
import UIComponent

extension ProjectDetailScreen {
    struct SetListSection: View {

        // MARK: Internal

        let sets: [ProjectDetailSetDisplay]
        let onStart: (String) -> Void

        var body: some View {
            VStack(
                alignment: .leading,
                spacing: Constant.titleSpacing,
            ) {
                StyledText(text: LocalizedText.ProjectDetail.setListSectionTitle)
                    .textStyle(.subtitle2)

                cards
            }
        }

        // MARK: Private

        private enum Constant {
            static let emptyStateVerticalPadding: CGFloat = 32
            static let titleSpacing: CGFloat = 16
            static let cardSpacing: CGFloat = 6
        }

        @ViewBuilder
        private var cards: some View {
            if sets.isEmpty {
                EmptyState(
                    displayModel: .init(
                        title: LocalizedText.ProjectDetail.setListSectionEmptyTitle,
                        message: LocalizedText.ProjectDetail.setListSectionEmptyMessage,
                    )
                ) {
                    ResourceImage(asset: .illust(.levelEntry))
                }
                .padding(.vertical, Constant.emptyStateVerticalPadding)
            } else {
                VStack(
                    alignment: .leading,
                    spacing: Constant.cardSpacing,
                ) {
                    ForEach(sets) { set in
                        LearningSetRow(
                            displayModel: .init(
                                label: set.label,
                                title: set.title,
                                questionCount: set.questionCount,
                                completedCount: set.completedCount,
                            ),
                            onStart: { onStart(set.id) },
                        )
                    }
                }
            }
        }

    }
}
