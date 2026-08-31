import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("HomeFeature 이동 intent")
struct HomeFeatureNavigationTests {
    @Test
    func `프로젝트 등록 CTA는 동일한 delegate를 전달한다`() async {
        let store = makeStore()

        await store.send(.view(.projectRegistrationTapped))
        await store.receive(.delegate(.projectRegistrationRequested))

        var presentState = HomeFeature.State()
        presentState.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        let presentStore = makeStore(state: presentState)
        await presentStore.send(.view(.projectRegistrationTapped))
        await presentStore.receive(.delegate(.projectRegistrationRequested))
    }

    @Test
    func `전체 보기와 카드 본문은 실제 destination 없이 intent만 전달한다`() async {
        let store = makeStore()

        await store.send(.view(.showAllProjectsTapped))
        await store.send(.view(.projectCardTapped(projectID: "project-1")))
        await store.receive(.delegate(.projectDetailRequested(projectID: "project-1")))
    }

    @Test
    func `유효한 세 ID만 학습 delegate로 전달한다`() async {
        var state = HomeFeature.State()
        state.projectLoad = .loaded(HomeTestFixture.manyProjectsPage)
        let store = makeStore(state: state)

        await store.send(.view(.learningTapped(projectID: "project-1")))
        await store.receive(
            .delegate(.learningRequested(projectID: "project-1", nextSetID: "set-1", nextQuestionID: "question-1"))
        )
        await store.send(.view(.learningTapped(projectID: "missing")))
    }

    private func makeStore(state: HomeFeature.State = .init()) -> TestStoreOf<HomeFeature> {
        TestStore(initialState: state) {
            HomeFeature(
                fetchLearningProjects: HomeLearningProjectsUseCaseMock(),
                fetchMemberProfile: HomeMemberProfileUseCaseMock(),
                learningProjectOutcomes: StubLearningProjectOutcomesUseCase(),
            )
        }
    }
}
