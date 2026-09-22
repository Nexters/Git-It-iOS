import ComposableArchitecture
import Foundation
import Testing

@testable import Feature

@MainActor
@Suite("ProjectDetailRouterFeature 화면 전환과 위임")
struct ProjectDetailRouterFeatureTests {

    // MARK: Internal

    @Test
    func `저장한 문제 화면은 프로젝트 필터가 고정된 채로 시작한다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        #expect(store.state.savedQuestions.selectedProjectID == ProjectDetailTestFixture.projectID)
        #expect(store.state.savedQuestions.isBackControlPresented)

        await store.send(
            .projectDetail(.delegate(.savedQuestionsRequested(projectID: ProjectDetailTestFixture.projectID)))
        )

        #expect(store.state.activeScreen == .savedQuestions)
        #expect(store.state.screenTransitions.map(\.cause) == [.savedQuestionsRequested])
    }

    @Test
    func `저장한 문제를 고르면 준비를 요청하고 아직 화면을 바꾸지 않는다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        await store.send(
            .projectDetail(.delegate(.savedQuestionsRequested(projectID: ProjectDetailTestFixture.projectID)))
        )

        let bookmark = ProjectDetailTestFixture.savedQuizList.bookmarks[0]
        await store.send(.savedQuestions(.delegate(.questionSelected(bookmark))))
        await store.receive(
            .singleQuestionEntry(.input(.questionRequested(
                setID: "set-0",
                questionID: "quiz-0",
            )))
        )

        #expect(store.state.activeScreen == .savedQuestions)
    }

    @Test
    func `준비가 끝나면 단일 문제 화면으로 전환한다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        let quiz = QuizTestFixture.unansweredSet.quizzes[0]

        await store.send(.singleQuestionEntry(.delegate(.questionPrepared(
            question: quiz,
            projectID: ProjectDetailTestFixture.projectID,
        ))))

        #expect(store.state.activeScreen == .singleQuestion)
        #expect(store.state.singleQuestion?.question == quiz)
        #expect(store.state.singleQuestion?.questionNumber == nil)
        #expect(
            store.state.singleQuestion?.advanceActionTitle
                == ProjectDetailRouterFeature.singleQuestionAdvanceActionTitle
        )
        #expect(
            store.state.screenTransitions.map(\.cause)
                == [.singleQuestionPrepared(questionID: quiz.id)]
        )
    }

    @Test
    func `준비에 실패하면 화면을 바꾸지 않는다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.singleQuestionEntry(.delegate(.preparationFailed(.quizUnavailable))))

        #expect(store.state.activeScreen == .projectDetail)
        #expect(store.state.singleQuestion == nil)
        #expect(store.state.screenTransitions.isEmpty)
    }

    @Test
    func `단일 문제 결과에서 진행하면 저장한 문제 목록으로 돌아간다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        await store.send(.singleQuestionEntry(.delegate(.questionPrepared(
            question: QuizTestFixture.unansweredSet.quizzes[0],
            projectID: ProjectDetailTestFixture.projectID,
        ))))

        await store.send(.singleQuestion(.delegate(.advanceRequested)))

        #expect(store.state.activeScreen == .savedQuestions)
        #expect(store.state.singleQuestion == nil)
        #expect(store.state.screenTransitions.last?.cause == .singleQuestionFinished)
    }

    @Test
    func `단일 문제 화면의 뒤로가기도 저장한 문제 목록으로 돌아간다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        await store.send(.singleQuestionEntry(.delegate(.questionPrepared(
            question: QuizTestFixture.unansweredSet.quizzes[0],
            projectID: ProjectDetailTestFixture.projectID,
        ))))

        await store.send(.singleQuestion(.delegate(.backRequested)))

        #expect(store.state.activeScreen == .savedQuestions)
        #expect(store.state.singleQuestion == nil)
        #expect(store.state.screenTransitions.last?.cause == .singleQuestionFinished)
    }

    @Test
    func `저장한 문제 화면의 뒤로가기는 상세 화면으로 되돌린다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        await store.send(
            .projectDetail(.delegate(.savedQuestionsRequested(projectID: ProjectDetailTestFixture.projectID)))
        )

        await store.send(.savedQuestions(.delegate(.backRequested)))

        #expect(store.state.activeScreen == .projectDetail)
        #expect(store.state.screenTransitions.last?.cause == .backRequested)
    }

    @Test
    func `세트 시작과 외부 URL과 삭제 완료와 이탈은 그대로 상위로 올라간다`() async throws {
        let store = makeStore()
        store.exhaustivity = .off
        let url = try #require(URL(string: ProjectDetailTestFixture.repositoryURL))

        await store.send(.projectDetail(.delegate(.setStartRequested(
            projectID: ProjectDetailTestFixture.projectID,
            setID: "set-1",
            label: "CHAPTER 2",
        ))))
        await store.receive(.delegate(.learningSetRequested(
            projectID: ProjectDetailTestFixture.projectID,
            setID: "set-1",
            label: "CHAPTER 2",
        )))
        #expect(store.state.activeScreen == .projectDetail)

        await store.send(.projectDetail(.delegate(.externalURLRequested(url))))
        await store.receive(.delegate(.externalURLRequested(url)))

        await store.send(
            .projectDetail(.delegate(.projectDeleted(projectID: ProjectDetailTestFixture.projectID)))
        )
        await store.receive(.delegate(.projectDeleted(projectID: ProjectDetailTestFixture.projectID)))

        await store.send(.projectDetail(.delegate(.dismissRequested)))
        await store.receive(.delegate(.dismissRequested))
    }

    // MARK: Private

    private func makeStore() -> TestStoreOf<ProjectDetailRouterFeature> {
        TestStore(
            initialState: ProjectDetailRouterFeature.State(projectID: ProjectDetailTestFixture.projectID)
        ) {
            ProjectDetailRouterFeature(
                project: ProjectUseCaseDetailStub(
                    results: [.success(ProjectDetailTestFixture.mixedProgressDetail)]
                ),
                quizDetail: QuizDetailUseCaseMock(
                    quizSetResults: [.success(QuizTestFixture.unansweredSet)],
                    bookmarkListResults: [.success(ProjectDetailTestFixture.savedQuizList)],
                ),
            )
        }
    }

}
