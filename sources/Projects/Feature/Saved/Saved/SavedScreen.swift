import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - SavedScreen

@ViewAction(for: SavedFeature.self)
struct SavedScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<SavedFeature>

    var body: some View {
        Group {
            if case .failed = store.loadStatus {
                ErrorView(
                    isBackControlPresented: store.isBackControlPresented,
                    onBack: { send(.backTapped) },
                    onRetry: { send(.retryTapped) },
                )
            } else {
                content
            }
        }
        .task { await store.send(.view(.task)).finish() }
    }

    // MARK: Private

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(
                title: "저장한 문제",
                style: .largeTitle,
                leading: store.isBackControlPresented ? .back : nil,
                onLeadingTap: { send(.backTapped) },
            )
            .designSystemScreenMargin()

            if store.isEmpty {
                Spacer(minLength: 0)

                EmptyState(
                    title: "bookmarks = []",
                    message: "아직 저장한 문제가 없습니다.\n다시 볼 문제를 저장해 보세요.",
                ) {
                    ResourceAnimation(asset: .storageEmpty, isLooping: false)
                }
                .designSystemScreenMargin()

                Spacer(minLength: 0)
            } else {
                ScrollView {
                    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
                        ForEach(SavedQuestionDisplay.list(questions: store.collection?.bookmarks ?? [])) { question in
                            QuestionRow(
                                prompt: question.prompt,
                                actionTitle: SavedQuestionDisplay.actionTitle,
                                onSolveTap: { solve(questionID: question.id) },
                            )
                        }
                    }
                    .designSystemScreenMargin()
                    .padding(.vertical, Constant.contentVerticalPadding)
                }
            }
        }
    }

    private func solve(questionID: String) {
        guard let question = store.collection?.bookmarks.first(where: { $0.questionID == questionID })
        else { return }
        send(.solveTapped(question))
    }

}

// MARK: SavedScreen.Constant

extension SavedScreen {
    fileprivate enum Constant {
        static let contentVerticalPadding: CGFloat = 16
    }
}
