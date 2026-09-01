import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@MainActor
@Suite("HomeFeature 학습 세트 생성 결과 관찰")
struct HomeFeatureGenerationOutcomeTests {

    @Test
    func `task는 generationOutcomeObservation이 idle일 때만 관찰 Effect를 시작하고 재호출 시 중복 구독하지 않는다`() async {
        let learningProjectOutcomes = StubLearningProjectOutcomesUseCase()
        let profile = HomeMemberProfileUseCaseMock(
            results: [.success(HomeTestFixture.profileWithBoth)],
            suspendsRequests: true,
        )
        let projects = HomeLearningProjectsUseCaseMock(
            results: [.success(HomeTestFixture.oneProjectPage)],
            suspendsRequests: true,
        )
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: profile,
                learningProjectOutcomes: learningProjectOutcomes,
            )
        }

        await store.send(.view(.task)) {
            $0.profileLoad = .loading
            $0.projectLoad = .loading
            $0.profileRequestID = 1
            $0.projectRequestID = 1
            $0.generationOutcomeObservation = .observing
        }
        while await profile.snapshot().pendingCount == 0 { await Task.yield() }
        await profile.resumeNext()
        await store.receive(.effect(.profileLoadFinished(requestID: 1, result: .success(HomeTestFixture.profileWithBoth)))) {
            $0.profileLoad = .loaded(HomeTestFixture.profileWithBoth)
        }
        while await projects.snapshot().pendingCount == 0 { await Task.yield() }
        await projects.resumeNext()
        await store.receive(.effect(.projectsLoadFinished(requestID: 1, result: .success(HomeTestFixture.oneProjectPage)))) {
            $0.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        }

        await store.send(.view(.task))

        #expect(await profile.snapshot().callCount == 1)
        #expect(await projects.snapshot().callCount == 1)

        await learningProjectOutcomes.finish()
        await store.finish()
    }

    @Test
    func `generationOutcomeReceived는 로딩 중이 아니면 프로젝트 목록을 다시 조회한다`() async {
        let learningProjectOutcomes = StubLearningProjectOutcomesUseCase()
        let projects = HomeLearningProjectsUseCaseMock(results: [
            .success(HomeTestFixture.oneProjectPage),
            .success(HomeTestFixture.manyProjectsPage),
        ])
        var state = HomeFeature.State()
        state.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        state.generationOutcomeObservation = .observing
        let store = TestStore(initialState: state) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: HomeMemberProfileUseCaseMock(),
                learningProjectOutcomes: learningProjectOutcomes,
            )
        }

        await learningProjectOutcomes.emit(
            GenerationOutcome(projectID: "project-1", status: .completed)
        )
        await store.receive(
            .effect(.generationOutcomeReceived(GenerationOutcome(projectID: "project-1", status: .completed)))
        ) {
            $0.projectLoad = .loading
            $0.projectRequestID = 1
        }
        await store.receive(.effect(.projectsLoadFinished(requestID: 1, result: .success(HomeTestFixture.manyProjectsPage)))) {
            $0.projectLoad = .loaded(HomeTestFixture.manyProjectsPage)
        }

        await learningProjectOutcomes.finish()
        await store.finish()
    }

    @Test
    func `reloadRequested는 projectLoad가 loading이 아닐 때만 새 조회를 시작한다`() async {
        let projects = HomeLearningProjectsUseCaseMock(results: [.success(HomeTestFixture.oneProjectPage)])
        var state = HomeFeature.State()
        state.projectLoad = .loading
        let store = TestStore(initialState: state) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: HomeMemberProfileUseCaseMock(),
                learningProjectOutcomes: StubLearningProjectOutcomesUseCase(),
            )
        }

        await store.send(.view(.reloadRequested))

        #expect(await projects.snapshot().callCount == 0)
    }

}
