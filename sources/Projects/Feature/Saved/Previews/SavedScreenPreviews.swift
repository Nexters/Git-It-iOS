import ComposableArchitecture
import DomainUseCaseInterface
import SwiftUI
import UIComponent

private let previewCollection = QuizBookmarkList(
    totalCount: 4,
    projects: [
        QuizBookmarkProject(
            id: "project-1",
            name: "Flask",
        ),
        QuizBookmarkProject(
            id: "project-2",
            name: "Now in Android",
        ),
    ],
    bookmarks: [
        QuizBookmark(
            projectID: "project-2",
            projectName: "Now in Android",
            setID: "set-2",
            setLabel: "Set 2",
            problemNumber: 1,
            quizID: "question-0",
            prompt: "sansio/blueprints.py에 정의된 BlueprintSetupState 클래스는 어떤 목적을 가진 객체인가?",
        ),
        QuizBookmark(
            projectID: "project-1",
            projectName: "Flask",
            setID: "set-0",
            setLabel: "Set 1",
            problemNumber: 3,
            quizID: "question-1",
            prompt: "Composition 패키지가 Domain에 의존해도 되는 이유는 무엇인가?",
        ),
        QuizBookmark(
            projectID: "project-1",
            projectName: "Flask",
            setID: "set-1",
            setLabel: "Set 2",
            problemNumber: 2,
            quizID: "question-2",
            prompt: "생성자 주입이 Service Locator보다 나은 점을 설명하세요.",
        ),
        QuizBookmark(
            projectID: "project-2",
            projectName: "Now in Android",
            setID: "set-3",
            setLabel: "Set 3",
            problemNumber: 4,
            quizID: "question-3",
            prompt: "androidApp과 desktopApp이 공통으로 쓰는 코드는 어디에 있나요?",
        ),
    ],
)

private func previewState(
    collection: QuizBookmarkList?,
    loadStatus: SavedFeature.LoadStatus,
) -> SavedFeature.State {
    var state = SavedFeature.State()
    state.collection = collection
    state.loadStatus = loadStatus
    return state
}

#Preview("저장한 문제 · 목록") {
    ScreenContainer {
        SavedScreen(
            store: Store(
                initialState: previewState(
                    collection: previewCollection,
                    loadStatus: .loaded,
                )
            ) { EmptyReducer() }
        )
    }
}

#Preview("저장한 문제 · 빈 상태") {
    ScreenContainer {
        SavedScreen(
            store: Store(
                initialState: previewState(
                    collection: QuizBookmarkList(
                        totalCount: 0,
                        projects: [],
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
                initialState: previewState(
                    collection: nil,
                    loadStatus: .failed(.temporarilyUnavailable),
                )
            ) { EmptyReducer() }
        )
    }
}
