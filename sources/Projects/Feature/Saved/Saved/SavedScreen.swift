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
            ScreenContainer {
                ErrorView(
                    isBackControlPresented: store.isBackControlPresented,
                    onBack: { send(.backTapped) },
                    onRetry: { send(.retryTapped) },
                )
            }

        case (_, true):
            ScreenContainer {
                VStack(spacing: 0) {
                    header

                    Spacer(minLength: 0)

                    EmptyState(
                        title: "Nothing saved yet.",
                        message: "아직 저장한 문제가 없네요!\n다시 확인하고 싶은 문제를 저장해 보세요.",
                    ) {
                        ResourceAnimation(asset: .storageEmpty, isLooping: true)
                    }
                    .designSystemScreenMargin()

                    Spacer(minLength: 0)
                }
            }

        case (_, false):
            OverlayContainer {
                header
            } content: {
                content
            }
        }
    }

    private var header: some View {
        VStack(spacing: Constant.headerBottomPadding) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Constant.headerVerticalSpacing) {
                    if store.isBackControlPresented {
                        IconGlassButton.neutral(
                            icon: ScreenControlBar.Control.back.icon,
                            label: ScreenControlBar.Control.back.label,
                            size: .medium,
                            action: { send(.backTapped) },
                        )
                        .frame(height: Constant.headerRowHeight)
                    }
                    ScreenHeaderTitle(title: "저장한 문제")
                        .frame(height: Constant.headerRowHeight)
                }

                Spacer()
            }

            if isFilterPresented {
                FilterSection(
                    projects: store.collection?.availableProjects ?? [],
                    selectedProjectID: store.selectedProjectID,
                    count: store.collection?.totalCount ?? 0,
                    onSelect: { send(.filterSelected(projectID: $0)) },
                )
            }
        }
        .designSystemScreenMargin()
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .designSystemBackground(.quizTopScrim)

    }

    private var content: some View {
        VStack(alignment: .leading, spacing: LayoutToken.compactSpacing) {
            ForEach(
                SavedQuestionDisplay.list(
                    questions: store.collection?.bookmarks ?? [],
                    bookmarkOverrides: store.bookmarkOverrides,
                )
            ) { question in
                SavedQuestionCard(
                    metadata: question.metadata,
                    prompt: question.prompt,
                    actionTitle: SavedQuestionDisplay.actionTitle,
                    isBookmarked: question.isBookmarked,
                    onActionTap: { solve(questionID: question.id) },
                    onBookmarkTap: { toggleBookmark(questionID: question.id) },
                )
            }
        }
        .designSystemScreenMargin()
        .padding(.top, isFilterPresented ? 0 : Constant.listTopPadding)
        .padding(.bottom, Constant.contentBottomPadding)
    }

    private var isFilterPresented: Bool {
        (store.collection?.totalCount ?? 0) > 0
    }

    private func solve(questionID: String) {
        guard let question = store.collection?.bookmarks.first(where: { $0.questionID == questionID })
        else { return }
        send(.solveTapped(question))
    }

    private func toggleBookmark(questionID: String) {
        guard let question = store.collection?.bookmarks.first(where: { $0.questionID == questionID })
        else { return }
        send(.bookmarkToggleTapped(question))
    }

}

// MARK: SavedScreen.Constant

extension SavedScreen {
    fileprivate enum Constant {
        static let listTopPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 24
        static let headerTitleHeight: CGFloat = 32
        static let headerRowHeight: CGFloat = 40
        static let headerVerticalSpacing: CGFloat = 16
        static let headerBottomPadding: CGFloat = 14
    }
}
