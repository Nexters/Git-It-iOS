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
        screen
            .task { await store.send(.view(.task)).finish() }
    }

    // MARK: Private

    @ViewBuilder
    private var screen: some View {
        switch (store.loadStatus, store.isEmpty) {
        case (.failed, _):
            ScreenContainer { _ in
                ErrorView(
                    isBackControlPresented: store.isBackControlPresented,
                    onBack: { send(.backTapped) },
                    onRetry: { send(.retryTapped) },
                )
            }

        case (_, true):
            ScreenContainer { _ in
                VStack(spacing: 0) {
                    header

                    Spacer(minLength: 0)

                    EmptyState(
                        title: "bookmarks = []",
                        message: "아직 저장한 문제가 없습니다.\n다시 볼 문제를 저장해 보세요.",
                    ) {
                        ResourceAnimation(asset: .storageEmpty, isLooping: false)
                    }
                    .designSystemScreenMargin()

                    Spacer(minLength: 0)
                }
            }

        case (_, false):
            content
        }
    }

    private var header: some View {
        ScreenHeader(
            title: "저장한 문제",
            style: .largeTitle,
            leading: store.isBackControlPresented ? .back : nil,
            onLeadingTap: { send(.backTapped) },
        )
        .designSystemScreenMargin()
    }

    private var content: some View {
        OverlayContainer { layoutMetrics in
            ScreenOverlayHeader(
                title: "저장한 문제",
                style: .largeTitle,
                leading: store.isBackControlPresented ? .back : nil,
                layoutMetrics: layoutMetrics,
                onLeadingTap: { send(.backTapped) },
            )
        } content: { _ in
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
