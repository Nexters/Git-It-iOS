import DesignSystem
import SwiftUI
import UIComponent

extension SavedScreen {
    struct QuestionCollectionView: View {

        // MARK: Internal

        let questions: [SavedQuestionDisplay]
        let isFailed: Bool
        let onBookmarkToggle: (String) -> Void
        let onSolve: (String) -> Void

        var body: some View {
            switch (isFailed, questions.isEmpty) {
            case (true, _):
                centered {
                    VStack(spacing: Constant.failureTextSpacing) {
                        StyledText(text: "저장한 문제를 불러오지 못했어요")
                            .textStyle(.subtitle1)
                            .multilineTextAlignment(.center)
                        StyledText(text: "잠시 후 다시 시도해 주세요.")
                            .textStyle(.body2)
                            .foregroundColorToken(.grey400)
                            .multilineTextAlignment(.center)
                    }
                }

            case (false, true):
                centered {
                    EmptyState(
                        displayModel: .init(
                            title: "Nothing saved yet.",
                            message: "아직 저장한 문제가 없네요!\n다시 확인하고 싶은 문제를 저장해 보세요.",
                        )
                    ) {
                        ResourceAnimation(asset: .storageEmpty)
                    }
                    .designSystemScreenMargin()
                }

            case (false, false):
                list
            }
        }

        // MARK: Private

        private enum Constant {
            static let failureTextSpacing: CGFloat = 10
        }

        private var list: some View {
            VStack(
                alignment: .leading,
                spacing: LayoutToken.compactSpacing,
            ) {
                ForEach(questions) { question in
                    SavedQuestionCard(
                        displayModel: .init(
                            metadata: question.metadata,
                            prompt: question.prompt,
                            actionTitle: SavedQuestionDisplay.actionTitle,
                        ),
                        isBookmarked: Binding(
                            get: { question.isBookmarked },
                            set: { _ in onBookmarkToggle(question.id) },
                        ),
                        onActionTap: { onSolve(question.id) },
                    )
                }
            }
            .designSystemScreenMargin()
        }

        private func centered(@ViewBuilder content: () -> some View) -> some View {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                content()

                Spacer(minLength: 0)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
            )
        }

    }
}
