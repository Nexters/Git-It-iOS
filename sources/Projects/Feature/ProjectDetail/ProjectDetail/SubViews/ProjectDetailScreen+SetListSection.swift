import DesignSystem
import SwiftUI
import UIComponent

extension ProjectDetailScreen {
    struct SetListSection: View {

        // MARK: Internal

        let sets: [ProjectDetailSetDisplay]
        let onStart: (String) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
                StyledText.subtitle2("학습 세트")

                cards
            }
        }

        // MARK: Private

        private enum Constant {
            static let emptyStateVerticalPadding: CGFloat = 32
        }

        @ViewBuilder
        private var cards: some View {
            if sets.isEmpty {
                EmptyState(
                    title: "sets = []",
                    message: "아직 만들어진 학습 세트가 없습니다.",
                ) {
                    ResourceImage(asset: .illust(.levelEntry))
                }
                .padding(.vertical, Constant.emptyStateVerticalPadding)
            } else {
                VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
                    ForEach(sets) { set in
                        LearningSetRow(
                            label: set.label,
                            title: set.title,
                            questionCount: set.questionCount,
                            completedCount: set.completedCount,
                            onStart: { onStart(set.id) },
                        )
                    }
                }
            }
        }

    }
}
