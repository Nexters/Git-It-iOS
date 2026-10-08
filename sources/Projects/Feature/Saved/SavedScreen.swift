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
        OverlayContainer {
            header
        } content: {
            content
        } footer: {
            footer
        }
        .task { await send(.task).finish() }
    }

    // MARK: Private

    private var isFailed: Bool {
        if case .failed = store.loadStatus {
            return true
        }
        return false
    }

    private var questions: [SavedQuestionDisplay] {
        SavedQuestionDisplay.list(
            questions: store.collection?.bookmarks ?? [],
            bookmarkOverrides: store.bookmarkOverrides,
        )
    }

    private var header: some View {
        VStack(spacing: Constant.headerBottomPadding) {
            HStack(alignment: .top) {
                VStack(
                    alignment: .leading,
                    spacing: Constant.headerVerticalSpacing,
                ) {
                    if store.isBackControlPresented {
                        IconGlassButton(
                            icon: ScreenControlBar.Control.back.icon,
                            action: { send(.backTapped) },
                        )
                        .size(.medium)
                        .frame(height: Constant.headerRowHeight)
                    }
                    ScreenHeaderTitle(displayModel: .init(title: LocalizedText.Saved.title))
                        .frame(height: Constant.headerRowHeight)
                }

                Spacer()
            }

            if isFilterPresented {
                FilterSection(
                    projects: store.collection?.projects ?? [],
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
        Self.QuestionCollectionView(
            questions: questions,
            isFailed: isFailed,
            onBookmarkToggle: { toggleBookmark(questionID: $0) },
            onSolve: { solve(questionID: $0) },
        )
        .padding(.top, isFilterPresented ? 0 : Constant.listTopPadding)
        .padding(.bottom, Constant.contentBottomPadding)
    }

    @ViewBuilder
    private var footer: some View {
        if isFailed {
            FeedbackActionButton(
                title: LocalizedText.Saved.Retry.buttonTitle,
                action: { send(.retryTapped) },
            )
            .designSystemScreenMargin()
            .padding(.bottom, Constant.footerBottomPadding)
        }
    }

    private var isFilterPresented: Bool {
        (store.collection?.totalCount ?? 0) > 0
    }

    private func solve(questionID: String) {
        guard let question = store.collection?.bookmarks.first(where: { $0.quizID == questionID })
        else { return }
        send(.solveTapped(question))
    }

    private func toggleBookmark(questionID: String) {
        guard let question = store.collection?.bookmarks.first(where: { $0.quizID == questionID })
        else { return }
        send(.bookmarkToggleTapped(question))
    }

}

// MARK: SavedScreen.Constant

extension SavedScreen {
    fileprivate enum Constant {
        static let listTopPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 24
        static let footerBottomPadding: CGFloat = 24
        static let headerTitleHeight: CGFloat = 32
        static let headerRowHeight: CGFloat = 40
        static let headerVerticalSpacing: CGFloat = 16
        static let headerBottomPadding: CGFloat = 14
    }
}
