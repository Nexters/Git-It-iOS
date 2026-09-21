import ComposableArchitecture
import DomainProject
import Testing

@testable import Feature

@MainActor
@Suite("HomeFeature 이동 intent")
struct HomeFeatureNavigationTests {

    // MARK: Internal

    @Test
    func `프로젝트 등록 CTA는 동일한 delegate를 전달한다`() async {
        let store = makeStore()

        await store.send(.view(.projectRegistrationTapped))
        await store.receive(.delegate(.projectRegistrationRequested))

        var presentState = HomeFeature.State()
        presentState.projectSummaries.load = .loaded(HomeTestFixture.oneProjectPage)
        let presentStore = makeStore(state: presentState)
        await presentStore.send(.view(.projectRegistrationTapped))
        await presentStore.receive(.delegate(.projectRegistrationRequested))
    }

    @Test
    func `전체 보기와 카드 본문은 실제 destination 없이 intent만 전달한다`() async {
        let store = makeStore()

        await store.send(.view(.showAllProjectsTapped))
        await store.receive(.delegate(.allProjectsRequested))
        await store.send(.view(.projectCardTapped(projectID: "project-1")))
        await store.receive(.delegate(.projectDetailRequested(projectID: "project-1")))
    }

    @Test
    func `적재된 목록에서 다음 퀴즈가 있는 프로젝트만 학습 delegate로 전달한다`() async {
        var state = HomeFeature.State()
        state.projectSummaries.load = .loaded(HomeTestFixture.manyProjectsPage)
        let store = makeStore(state: state)

        await store.send(.view(.learningTapped(projectID: "project-1")))
        await store.receive(
            .delegate(.learningRequested(projectID: "project-1", nextSetID: "set-1"))
        )
        await store.send(.view(.learningTapped(projectID: "missing")))
    }

    @Test
    func `다음 퀴즈가 없는 프로젝트는 학습 delegate를 전달하지 않는다`() async {
        var state = HomeFeature.State()
        state.projectSummaries.load = .loaded(ProjectList(
            summaries: [HomeTestFixture.project(index: 0, hasLearningIDs: false)],
            hasNextPage: false,
            isLoaded: true,
        ))
        let store = makeStore(state: state)

        await store.send(.view(.learningTapped(projectID: "project-0")))
    }

    @Test
    func `목록이 적재되기 전에는 학습 delegate를 전달하지 않는다`() async {
        let store = makeStore()

        await store.send(.view(.learningTapped(projectID: "project-0")))
    }

    // MARK: Private

    private func makeStore(state: HomeFeature.State = .init()) -> TestStoreOf<HomeFeature> {
        let projects = ProjectUseCaseMock()
        let profile = UserInfoUseCaseSuspendableProfileMock(results: [.success(HomeTestFixture.profileWithBoth)])
        return TestStore(initialState: state) {
            HomeFeature(
                projects: { await projects.projects() },
                refreshProjects: { try await projects.refresh() },
                profile: profile.fetchProfile,
            )
        }
    }

}
