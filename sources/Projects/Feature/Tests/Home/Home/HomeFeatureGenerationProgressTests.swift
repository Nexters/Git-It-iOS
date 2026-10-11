import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("HomeFeature 생성 진행 중")
struct HomeFeatureGenerationProgressTests {

    // MARK: Internal

    @Test
    func `진행 중 입력을 받으면 등록 진입 delegate를 보내지 않는다`() async {
        let store = makeStore()

        await store.send(.input(.generationProgressChanged(isInProgress: true))) {
            $0.isGenerationInProgress = true
        }
        await store.send(.view(.projectRegistrationTapped))
    }

    @Test
    func `진행이 해제되면 등록 진입 delegate가 다시 전달된다`() async {
        var state = HomeFeature.State()
        state.isGenerationInProgress = true
        let store = makeStore(state: state)

        await store.send(.input(.generationProgressChanged(isInProgress: false))) {
            $0.isGenerationInProgress = false
        }
        await store.send(.view(.projectRegistrationTapped))
        await store.receive(.delegate(.projectRegistrationRequested))
    }

    @Test
    func `같은 진행 상태가 다시 도착해도 상태가 흔들리지 않는다`() async {
        let store = makeStore()

        await store.send(.input(.generationProgressChanged(isInProgress: true))) {
            $0.isGenerationInProgress = true
        }
        await store.send(.input(.generationProgressChanged(isInProgress: true)))
        await store.send(.view(.projectRegistrationTapped))
    }

    @Test
    func `진행 중에도 카드 본문과 전체 보기 동작은 달라지지 않는다`() async {
        var state = HomeFeature.State()
        state.isGenerationInProgress = true
        state.projectSummaries.load = .loaded(HomeTestFixture.manyProjectsPage)
        let store = makeStore(state: state)

        await store.send(.view(.showAllProjectsTapped))
        await store.receive(.delegate(.allProjectsRequested))
        await store.send(.view(.projectCardTapped(projectID: "project-1")))
        await store.receive(.delegate(.projectDetailRequested(projectID: "project-1")))
        await store.send(.view(.learningTapped(projectID: "project-1")))
        await store.receive(
            .delegate(.learningRequested(
                projectID: "project-1",
                nextSetID: "set-1",
            ))
        )
    }

    @Test
    func `진행 중에도 프로필 재시도 조회는 그대로 수행된다`() async {
        let profile = UserInfoUseCaseSuspendableProfileMock(results: [.success(HomeTestFixture.profileWithBoth)])
        var state = HomeFeature.State()
        state.isGenerationInProgress = true
        state.profile.load = .failed(.temporarilyUnavailable)
        let store = makeStore(
            profile: profile,
            state: state,
        )

        await store.send(.view(.profileRetryTapped))
        await store.receive(.profile(.input(.load))) {
            $0.profile.load = .loading
            $0.profile.requestID = 1
        }
        await store.receive(
            .profile(.effect(.profileLoadFinished(
                requestID: 1,
                result: .success(HomeTestFixture.profileWithBoth),
            )))
        ) {
            $0.profile.load = .loaded(HomeTestFixture.profileWithBoth)
        }

        #expect(store.state.isGenerationInProgress)
        #expect(await profile.snapshot().callCount == 1)
    }

    @Test
    func `진행 중에도 프로젝트 갱신 재시도는 그대로 수행된다`() async {
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        var state = HomeFeature.State()
        state.isGenerationInProgress = true
        state.projectSummaries.load = .failed(.temporarilyUnavailable)
        let store = makeStore(
            projects: projects,
            state: state,
        )

        await store.send(.view(.projectRetryTapped))
        await store.receive(.projectSummaries(.input(.refresh))) {
            $0.projectSummaries.load = .loading
            $0.projectSummaries.requestID = 1
        }
        await store.receive(.projectSummaries(.effect(.refreshFinished(
            requestID: 1,
            error: nil,
        ))))

        #expect(await projects.snapshot().refreshCallCount == 1)
    }

    // MARK: Private

    private func makeStore(
        projects: ProjectUseCaseMock = ProjectUseCaseMock(),
        profile: UserInfoUseCaseSuspendableProfileMock = UserInfoUseCaseSuspendableProfileMock(
            results: [.success(HomeTestFixture.profileWithBoth)]
        ),
        state: HomeFeature.State = .init(),
    ) -> TestStoreOf<HomeFeature> {
        TestStore(initialState: state) {
            HomeFeature(
                projects: { await projects.projects() },
                refreshProjects: { try await projects.refresh() },
                profile: profile.fetchProfile,
            )
        }
    }

}
