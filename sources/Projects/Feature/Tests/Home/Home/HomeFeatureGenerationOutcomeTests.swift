import ComposableArchitecture
import DomainLearningProject
import Foundation
import Testing

@testable import Feature

@MainActor
@Suite("HomeFeature 학습 세트 생성 결과 관찰")
struct HomeFeatureGenerationOutcomeTests {

    @Test
    func `task가 다시 전달되면 이전 생성 결과 관찰을 대체해 하나만 유지한다`() async {
        let observeGenerationOutcomes = StubTrackGenerationUseCase()
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
                fetchMemberProfile: profile.fetchProfile,
                trackGeneration: observeGenerationOutcomes,
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
        while await observeGenerationOutcomes.establishedSubscriptionCount() < 2 { await Task.yield() }
        while await observeGenerationOutcomes.activeSubscriptionCount() != 1 { await Task.yield() }

        #expect(await observeGenerationOutcomes.activeSubscriptionCount() == 1)
        #expect(await profile.snapshot().callCount == 1)
        #expect(await projects.snapshot().callCount == 1)

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `화면을 벗어났다 돌아오면 생성 결과 관찰을 다시 시작해 결과를 반영한다`() async {
        let observeGenerationOutcomes = StubTrackGenerationUseCase()
        let projects = HomeLearningProjectsUseCaseMock(results: [.success(HomeTestFixture.manyProjectsPage)])
        let store = TestStore(initialState: Self.loadedState()) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: HomeMemberProfileUseCaseMock().fetchProfile,
                trackGeneration: observeGenerationOutcomes,
            )
        }

        let firstTask = await store.send(.view(.task))
        while await observeGenerationOutcomes.activeSubscriptionCount() == 0 { await Task.yield() }
        await firstTask.cancel()
        while await observeGenerationOutcomes.activeSubscriptionCount() != 0 { await Task.yield() }

        await store.send(.view(.task))
        while await observeGenerationOutcomes.activeSubscriptionCount() == 0 { await Task.yield() }
        await observeGenerationOutcomes.emit(
            GenerationOutcome(projectID: "project-1", status: .completed)
        )
        await store.receive(
            .effect(.generationOutcomeReceived(GenerationOutcome(projectID: "project-1", status: .completed)))
        ) {
            $0.appliedOutcomeProjectIDs = ["project-1"]
            $0.projectRequestID = 1
        }
        await store.receive(.effect(.projectsLoadFinished(requestID: 1, result: .success(HomeTestFixture.manyProjectsPage)))) {
            $0.projectLoad = .loaded(HomeTestFixture.manyProjectsPage)
        }

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `화면을 벗어난 동안 끝난 생성 결과를 돌아왔을 때 반영한다`() async {
        let observeGenerationOutcomes = StubTrackGenerationUseCase()
        let projects = HomeLearningProjectsUseCaseMock(results: [.success(HomeTestFixture.manyProjectsPage)])
        let store = TestStore(initialState: Self.loadedState()) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: HomeMemberProfileUseCaseMock().fetchProfile,
                trackGeneration: observeGenerationOutcomes,
            )
        }

        let firstTask = await store.send(.view(.task))
        while await observeGenerationOutcomes.activeSubscriptionCount() == 0 { await Task.yield() }
        await firstTask.cancel()
        while await observeGenerationOutcomes.activeSubscriptionCount() != 0 { await Task.yield() }
        await observeGenerationOutcomes.store(
            GenerationState(records: [
                GenerationRecord(
                    githubRepoURL: "https://github.com/owner/project-1",
                    projectID: "project-1",
                    requestedAt: Date(timeIntervalSince1970: 1_800_000_000),
                    status: .completed,
                    finishedAt: Date(timeIntervalSince1970: 1_800_000_600),
                )
            ])
        )

        await store.send(.view(.task))
        await store.receive(
            .effect(.generationOutcomeReceived(GenerationOutcome(projectID: "project-1", status: .completed)))
        ) {
            $0.appliedOutcomeProjectIDs = ["project-1"]
            $0.projectRequestID = 1
        }
        await store.receive(.effect(.projectsLoadFinished(requestID: 1, result: .success(HomeTestFixture.manyProjectsPage)))) {
            $0.projectLoad = .loaded(HomeTestFixture.manyProjectsPage)
        }

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `generationOutcomeReceived는 로딩 중이 아니면 프로젝트 목록을 다시 조회한다`() async {
        let observeGenerationOutcomes = StubTrackGenerationUseCase()
        let projects = HomeLearningProjectsUseCaseMock(results: [
            .success(HomeTestFixture.oneProjectPage),
            .success(HomeTestFixture.manyProjectsPage),
        ])
        var state = HomeFeature.State()
        state.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        let store = TestStore(initialState: state) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: HomeMemberProfileUseCaseMock().fetchProfile,
                trackGeneration: observeGenerationOutcomes,
            )
        }

        await observeGenerationOutcomes.emit(
            GenerationOutcome(projectID: "project-1", status: .completed)
        )
        await store.receive(
            .effect(.generationOutcomeReceived(GenerationOutcome(projectID: "project-1", status: .completed)))
        ) {
            $0.appliedOutcomeProjectIDs = ["project-1"]
            $0.projectRequestID = 1
        }
        await store.receive(.effect(.projectsLoadFinished(requestID: 1, result: .success(HomeTestFixture.manyProjectsPage)))) {
            $0.projectLoad = .loaded(HomeTestFixture.manyProjectsPage)
        }

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `learningProjectsReloadRequested는 조회 중이면 즉시 재조회하지 않고 갱신을 예약한다`() async {
        let projects = HomeLearningProjectsUseCaseMock(results: [.success(HomeTestFixture.oneProjectPage)])
        var state = HomeFeature.State()
        state.projectLoad = .loading
        let store = TestStore(initialState: state) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: HomeMemberProfileUseCaseMock().fetchProfile,
                trackGeneration: StubTrackGenerationUseCase(),
            )
        }

        await store.send(.input(.learningProjectsReloadRequested)) {
            $0.isProjectRefreshPending = true
        }

        #expect(await projects.snapshot().callCount == 0)
    }

    @Test
    func `조회 중 도착한 생성 결과는 폐기되지 않고 조회 완료 후 재조회로 반영된다`() async {
        let observeGenerationOutcomes = StubTrackGenerationUseCase()
        let projects = HomeLearningProjectsUseCaseMock(results: [
            .success(HomeTestFixture.oneProjectPage),
            .success(HomeTestFixture.manyProjectsPage),
        ])
        var state = HomeFeature.State()
        state.projectLoad = .loading
        state.projectRequestID = 1
        let store = TestStore(initialState: state) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: HomeMemberProfileUseCaseMock().fetchProfile,
                trackGeneration: observeGenerationOutcomes,
            )
        }

        await store.send(.effect(.generationOutcomeReceived(GenerationOutcome(projectID: "project-1", status: .completed)))) {
            $0.appliedOutcomeProjectIDs = ["project-1"]
            $0.isProjectRefreshPending = true
        }
        #expect(await projects.snapshot().callCount == 0)

        await store.send(.effect(.projectsLoadFinished(requestID: 1, result: .success(HomeTestFixture.oneProjectPage)))) {
            $0.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
            $0.isProjectRefreshPending = false
            $0.projectRequestID = 2
        }
        await store.receive(.effect(.projectsLoadFinished(requestID: 2, result: .success(HomeTestFixture.manyProjectsPage)))) {
            $0.projectLoad = .loaded(HomeTestFixture.manyProjectsPage)
        }

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `이미 반영한 프로젝트의 동일 결과가 다시 도착해도 재조회하지 않는다`() async {
        let observeGenerationOutcomes = StubTrackGenerationUseCase()
        let projects = HomeLearningProjectsUseCaseMock(results: [.success(HomeTestFixture.manyProjectsPage)])
        var state = HomeFeature.State()
        state.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        state.appliedOutcomeProjectIDs = ["project-1"]
        let store = TestStore(initialState: state) {
            HomeFeature(
                fetchLearningProjects: projects,
                fetchMemberProfile: HomeMemberProfileUseCaseMock().fetchProfile,
                trackGeneration: observeGenerationOutcomes,
            )
        }

        await store.send(.effect(.generationOutcomeReceived(GenerationOutcome(projectID: "project-1", status: .completed))))

        #expect(await projects.snapshot().callCount == 0)

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    // MARK: Private

    private static func loadedState() -> HomeFeature.State {
        var state = HomeFeature.State()
        state.profileLoad = .loaded(HomeTestFixture.profileWithBoth)
        state.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        return state
    }

}
