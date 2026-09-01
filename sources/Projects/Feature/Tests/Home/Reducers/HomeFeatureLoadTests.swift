import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("HomeFeature 조회")
struct HomeFeatureLoadTests {
    @Test
    func `최초 task는 프로필과 프로젝트를 각각 한 번 조회하고 복귀 task는 재조회하지 않는다`() async {
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
                observeGenerationOutcomes: StubObserveGenerationOutcomesUseCase(),
            )
        }

        await store.send(.view(.task)) {
            $0.profileLoad = .loading
            $0.projectLoad = .loading
            $0.profileRequestID = 1
            $0.projectRequestID = 1
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
    }

    @Test
    func `프로필 재시도는 프로젝트를 보존하고 프로필만 조회한다`() async {
        let profile = HomeMemberProfileUseCaseMock(results: [.success(HomeTestFixture.profileWithBoth)])
        let projects = HomeLearningProjectsUseCaseMock(results: [.success(HomeTestFixture.oneProjectPage)])
        var state = HomeFeature.State()
        state.profileLoad = .failed(.temporarilyUnavailable)
        state.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        let store = TestStore(initialState: state) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: profile,
                observeGenerationOutcomes: StubObserveGenerationOutcomesUseCase(),
            )
        }

        await store.send(.view(.profileRetryTapped)) {
            $0.profileLoad = .loading
            $0.profileRequestID = 1
        }
        await store.receive(.effect(.profileLoadFinished(requestID: 1, result: .success(HomeTestFixture.profileWithBoth)))) {
            $0.profileLoad = .loaded(HomeTestFixture.profileWithBoth)
        }

        #expect(await profile.snapshot().callCount == 1)
        #expect(await projects.snapshot().callCount == 0)
    }

    @Test
    func `현재 request ID와 다른 응답은 상태를 바꾸지 않는다`() async {
        var state = HomeFeature.State()
        state.profileLoad = .loading
        state.profileRequestID = 2
        let store = TestStore(initialState: state) {
            HomeFeature(
                fetchLearningProjects: HomeLearningProjectsUseCaseMock(),
                fetchMemberProfile: HomeMemberProfileUseCaseMock(),
                observeGenerationOutcomes: StubObserveGenerationOutcomesUseCase(),
            )
        }

        await store.send(.effect(.profileLoadFinished(requestID: 1, result: .success(HomeTestFixture.profileWithBoth))))
    }

    @Test
    func `프로젝트 실패는 성공한 프로필을 보존하고 독립 실패 상태가 된다`() async {
        let profile = HomeMemberProfileUseCaseMock(
            results: [.success(HomeTestFixture.profileWithBoth)],
            suspendsRequests: true,
        )
        let projects = HomeLearningProjectsUseCaseMock(
            results: [.failure(.temporarilyUnavailable)],
            suspendsRequests: true,
        )
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: profile,
                observeGenerationOutcomes: StubObserveGenerationOutcomesUseCase(),
            )
        }

        await store.send(.view(.task)) {
            $0.profileLoad = .loading
            $0.projectLoad = .loading
            $0.profileRequestID = 1
            $0.projectRequestID = 1
        }
        while await profile.snapshot().pendingCount == 0 { await Task.yield() }
        await profile.resumeNext()
        await store.receive(.effect(.profileLoadFinished(requestID: 1, result: .success(HomeTestFixture.profileWithBoth)))) {
            $0.profileLoad = .loaded(HomeTestFixture.profileWithBoth)
        }
        while await projects.snapshot().pendingCount == 0 { await Task.yield() }
        await projects.resumeNext()
        await store.receive(.effect(.projectsLoadFinished(requestID: 1, result: .failure(.temporarilyUnavailable)))) {
            $0.projectLoad = .failed(.temporarilyUnavailable)
        }
    }
}
