import ComposableArchitecture
import DomainLearningProject
import SwiftUI
import UIComponent

private let previewCollection = BookmarkedQuestionCollection(
    totalCount: 4,
    availableProjects: [
        BookmarkedProject(id: "project-1", name: "Flask"),
        BookmarkedProject(id: "project-2", name: "Now in Android"),
    ],
    bookmarks: [
        BookmarkedQuestion(
            projectID: "project-2",
            projectName: "Now in Android",
            setID: "set-2",
            setLabel: "Set 2",
            problemNumber: 1,
            questionID: "question-0",
            prompt: "sansio/blueprints.py에 정의된 BlueprintSetupState 클래스는 어떤 목적을 가진 객체인가?",
        ),
        BookmarkedQuestion(
            projectID: "project-1",
            projectName: "Flask",
            setID: "set-0",
            setLabel: "Set 1",
            problemNumber: 3,
            questionID: "question-1",
            prompt: "Composition 패키지가 Domain에 의존해도 되는 이유는 무엇인가?",
        ),
        BookmarkedQuestion(
            projectID: "project-1",
            projectName: "Flask",
            setID: "set-1",
            setLabel: "Set 2",
            problemNumber: 2,
            questionID: "question-2",
            prompt: "생성자 주입이 Service Locator보다 나은 점을 설명하세요.",
        ),
        BookmarkedQuestion(
            projectID: "project-2",
            projectName: "Now in Android",
            setID: "set-3",
            setLabel: "Set 3",
            problemNumber: 4,
            questionID: "question-3",
            prompt: "androidApp과 desktopApp이 공통으로 쓰는 코드는 어디에 있나요?",
        ),
    ],
)

private func previewState(
    collection: BookmarkedQuestionCollection?,
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
