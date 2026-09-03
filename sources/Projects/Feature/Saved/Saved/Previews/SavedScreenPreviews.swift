import ComposableArchitecture
import DomainLearningProject
import SwiftUI
import UIComponent

private let previewCollection = BookmarkedQuestionCollection(
    totalCount: 2,
    availableProjects: ["project-1"],
    bookmarks: [
        BookmarkedQuestion(
            projectID: "project-1",
            setID: "set-0",
            questionID: "question-0",
            prompt: "Composition 패키지가 Domain에 의존해도 되는 이유는 무엇인가?",
        ),
        BookmarkedQuestion(
            projectID: "project-1",
            setID: "set-1",
            questionID: "question-1",
            prompt: "생성자 주입이 Service Locator보다 나은 점을 설명하세요.",
        ),
    ],
)

private func previewState(
    collection: BookmarkedQuestionCollection?,
    loadStatus: SavedFeature.LoadStatus,
) -> SavedFeature.State {
    var state = SavedFeature.State(projectFilter: "project-1", isBackControlPresented: true)
    state.collection = collection
    state.loadStatus = loadStatus
    return state
}

#Preview("저장한 문제 · 목록") {
    ScreenContainer {
        SavedScreen(
            store: Store(
                initialState: previewState(collection: previewCollection, loadStatus: .loaded)
            ) { EmptyReducer() }
        )
    }
}

#Preview("저장한 문제 · 빈 상태") {
    ScreenContainer {
        SavedScreen(
            store: Store(
                initialState: previewState(
                    collection: BookmarkedQuestionCollection(
                        totalCount: 0,
                        availableProjects: [],
                        bookmarks: [],
                    ),
                    loadStatus: .loaded,
                )
            ) { EmptyReducer() }
        )
    }
}

#Preview("저장한 문제 · 실패") {
    ScreenContainer {
        SavedScreen(
            store: Store(
                initialState: previewState(collection: nil, loadStatus: .failed(.temporarilyUnavailable))
            ) { EmptyReducer() }
        )
    }
}
