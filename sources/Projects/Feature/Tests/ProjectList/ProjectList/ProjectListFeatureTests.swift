import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@Suite("ProjectListFeature 프로젝트 목록")
struct ProjectListFeatureTests {

    // MARK: Internal

    @Test
    func `진입하면 프로젝트를 불러와 목록에 채운다`() async {
        let store = makeStore(fetchLearningProjects: HomeLearningProjectsUseCaseMock(
            results: [.success(HomeTestFixture.manyProjectsPage)]
        ))
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)

        #expect(store.state.initialLoad == .loaded)
        #expect(store.state.projects.count == HomeTestFixture.manyProjectsPage.items.count)
    }

    @Test
    func `조회에 실패하면 실패 상태를 남긴다`() async {
        let store = makeStore(fetchLearningProjects: HomeLearningProjectsUseCaseMock(
            results: [.failure(.temporarilyUnavailable)]
        ))
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)

        #expect(store.state.initialLoad == .failed(.temporarilyUnavailable))
    }

    @Test
    func `행을 누르면 프로젝트 상세를 요청한다`() async {
        let store = makeStore()

        await store.send(.view(.projectRowTapped(projectID: "project-0")))
        await store.receive(\.delegate.projectSelected)
    }

    @Test
    func `재생 버튼은 다음 세트로 이어하기를 요청한다`() async {
        let store = makeStore(fetchLearningProjects: HomeLearningProjectsUseCaseMock(
            results: [.success(HomeTestFixture.manyProjectsPage)]
        ))
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)

        await store.send(.view(.learningTapped(projectID: "project-1")))
        await store.receive(.delegate(.learningRequested(projectID: "project-1", nextSetID: "set-1")))
    }

    @Test
    func `다음 문제가 없는 프로젝트는 이어하기를 요청하지 않는다`() async {
        let page = LearningProjectPage(
            items: [HomeTestFixture.project(index: 0, hasLearningIDs: false)],
            hasNext: false,
        )
        let store = makeStore(fetchLearningProjects: HomeLearningProjectsUseCaseMock(results: [.success(page)]))
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)

        await store.send(.view(.learningTapped(projectID: "project-0")))
    }

    @Test
    func `삭제 모드에서는 재생 버튼이 이어하기를 요청하지 않는다`() async {
        let store = makeStore(mode: .deleting, fetchLearningProjects: HomeLearningProjectsUseCaseMock(
            results: [.success(HomeTestFixture.manyProjectsPage)]
        ))
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)

        await store.send(.view(.learningTapped(projectID: "project-1")))
    }

    @Test
    func `메뉴를 열면 메뉴 열림 모드가 된다`() async {
        let store = makeStore()

        await store.send(.view(.menuTapped)) {
            $0.mode = .menuPresented
        }
    }

    @Test
    func `메뉴 바깥을 누르면 메뉴가 닫힌다`() async {
        let store = makeStore(mode: .menuPresented)

        await store.send(.view(.menuDismissed)) {
            $0.mode = .browsing
        }
    }

    @Test
    func `메뉴에서 프로젝트 삭제를 고르면 삭제 모드가 된다`() async {
        let store = makeStore(mode: .menuPresented)

        await store.send(.view(.deletionMenuItemTapped)) {
            $0.mode = .deleting
        }
    }

    @Test
    func `삭제 모드에서 뒤로 가면 목록 모드로 돌아온다`() async {
        let store = makeStore(mode: .deleting)

        await store.send(.view(.backTapped)) {
            $0.mode = .browsing
        }
    }

    @Test
    func `목록 모드에서는 삭제 확인이 시작되지 않는다`() async {
        let deleteLearningProject = StubDeleteLearningProjectUseCase()
        let store = makeStore(deleteLearningProject: deleteLearningProject)

        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))

        #expect(await deleteLearningProject.callCount == 0)
    }

    @Test
    func `삭제 모드에서는 행을 눌러도 상세로 이동하지 않는다`() async {
        let store = makeStore(mode: .deleting)

        await store.send(.view(.projectRowTapped(projectID: "project-0")))
    }

    @Test
    func `삭제를 확인하기 전에는 삭제를 요청하지 않는다`() async {
        let deleteLearningProject = StubDeleteLearningProjectUseCase()
        let store = makeStore(mode: .deleting, deleteLearningProject: deleteLearningProject)

        await store.send(.view(.deleteButtonTapped(projectID: "project-0"))) {
            $0.deletion = .confirming(projectID: "project-0")
        }

        #expect(await deleteLearningProject.callCount == 0)
    }

    @Test
    func `삭제를 취소하면 확인 상태를 벗어난다`() async {
        let store = makeStore(mode: .deleting)

        await store.send(.view(.deleteButtonTapped(projectID: "project-0"))) {
            $0.deletion = .confirming(projectID: "project-0")
        }
        await store.send(.view(.deletionCancelled)) {
            $0.deletion = .idle
        }
    }

    @Test
    func `삭제에 성공하면 목록에서 그 프로젝트를 지운다`() async {
        let store = makeStore(
            mode: .deleting,
            fetchLearningProjects: HomeLearningProjectsUseCaseMock(
                results: [.success(HomeTestFixture.manyProjectsPage)]
            ),
            deleteLearningProject: StubDeleteLearningProjectUseCase(),
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)
        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.effect.deletionFinished)

        #expect(!store.state.projects.contains { $0.projectID == "project-0" })
        #expect(store.state.deletion == .idle)
        #expect(store.state.mode == .deleting)
    }

    @Test
    func `이미 사라진 프로젝트는 삭제 실패로 남기지 않는다`() async {
        let store = makeStore(
            mode: .deleting,
            fetchLearningProjects: HomeLearningProjectsUseCaseMock(
                results: [.success(HomeTestFixture.manyProjectsPage)]
            ),
            deleteLearningProject: StubDeleteLearningProjectUseCase(results: [.failure(.notFound)]),
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)
        await store.send(.view(.deleteButtonTapped(projectID: "project-1")))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.effect.deletionFinished)

        #expect(!store.state.projects.contains { $0.projectID == "project-1" })
        #expect(store.state.deletion == .idle)
    }

    @Test
    func `마지막 프로젝트를 지우면 삭제 모드를 벗어난다`() async {
        let store = makeStore(
            mode: .deleting,
            fetchLearningProjects: HomeLearningProjectsUseCaseMock(
                results: [.success(HomeTestFixture.manyProjectsPage)]
            ),
            deleteLearningProject: StubDeleteLearningProjectUseCase(),
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)
        for project in store.state.projects.map(\.projectID) {
            await store.send(.view(.deleteButtonTapped(projectID: project)))
            await store.send(.view(.deletionConfirmed))
            await store.receive(\.effect.deletionFinished)
        }

        #expect(store.state.projects.isEmpty)
        #expect(store.state.mode == .browsing)
    }

    @Test
    func `삭제 실패는 목록과 삭제 모드를 유지한다`() async {
        let store = makeStore(
            mode: .deleting,
            fetchLearningProjects: HomeLearningProjectsUseCaseMock(
                results: [.success(HomeTestFixture.manyProjectsPage)]
            ),
            deleteLearningProject: StubDeleteLearningProjectUseCase(results: [.failure(.temporarilyUnavailable)]),
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)
        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.effect.deletionFinished)

        #expect(store.state.projects.contains { $0.projectID == "project-0" })
        #expect(store.state.mode == .deleting)
        #expect(store.state.deletion == .failed(projectID: "project-0", error: .temporarilyUnavailable))
    }

    @Test
    func `삭제 실패 후에도 뒤로 가면 목록 모드로 돌아온다`() async {
        let store = makeStore(
            mode: .deleting,
            fetchLearningProjects: HomeLearningProjectsUseCaseMock(
                results: [.success(HomeTestFixture.manyProjectsPage)]
            ),
            deleteLearningProject: StubDeleteLearningProjectUseCase(results: [.failure(.temporarilyUnavailable)]),
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)
        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.effect.deletionFinished)

        await store.send(.view(.backTapped)) {
            $0.mode = .browsing
            $0.deletion = .idle
        }
    }

    @Test
    func `목록 끝에 닿으면 다음 페이지를 이어붙인다`() async {
        let fetchLearningProjects = HomeLearningProjectsUseCaseMock(
            results: [.success(Self.firstPage), .success(Self.secondPage)]
        )
        let store = makeStore(fetchLearningProjects: fetchLearningProjects)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)
        await store.send(.view(.listBottomReached))
        await store.receive(\.effect.projectsLoadFinished)

        #expect(store.state.projects.map(\.projectID) == [
            "project-0",
            "project-1",
            "project-2",
            "project-3",
            "project-4",
            "project-5",
        ])
        #expect(store.state.pagination == .exhausted)
        #expect(await fetchLearningProjects.requestedPageSnapshot() == [0, 1])
    }

    @Test
    func `다음 페이지가 없으면 목록 끝에 닿아도 다시 요청하지 않는다`() async {
        let fetchLearningProjects = HomeLearningProjectsUseCaseMock(
            results: [.success(HomeTestFixture.oneProjectPage)]
        )
        let store = makeStore(fetchLearningProjects: fetchLearningProjects)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)
        await store.send(.view(.listBottomReached))

        #expect(store.state.pagination == .exhausted)
        #expect(await fetchLearningProjects.snapshot().callCount == 1)
    }

    @Test
    func `다음 페이지를 불러오는 중에는 같은 요청을 반복하지 않는다`() async {
        let fetchLearningProjects = HomeLearningProjectsUseCaseMock(results: [.success(Self.secondPage)])
        let store = makeStore(
            fetchLearningProjects: fetchLearningProjects,
            initialLoad: .loaded,
            pagination: .loading(nextPage: 1),
        )

        await store.send(.view(.listBottomReached))

        #expect(await fetchLearningProjects.snapshot().callCount == 0)
    }

    @Test
    func `첫 조회 전에는 목록 끝에 닿아도 다음 페이지를 요청하지 않는다`() async {
        let fetchLearningProjects = HomeLearningProjectsUseCaseMock(results: [.success(Self.secondPage)])
        let store = makeStore(fetchLearningProjects: fetchLearningProjects)

        await store.send(.view(.listBottomReached))

        #expect(await fetchLearningProjects.snapshot().callCount == 0)
    }

    @Test
    func `다음 페이지 조회에 실패하면 재시도로 같은 페이지를 다시 요청한다`() async {
        let fetchLearningProjects = HomeLearningProjectsUseCaseMock(results: [
            .success(Self.firstPage),
            .failure(.temporarilyUnavailable),
            .success(Self.secondPage),
        ])
        let store = makeStore(fetchLearningProjects: fetchLearningProjects)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)
        await store.send(.view(.listBottomReached))
        await store.receive(\.effect.projectsLoadFinished)

        #expect(store.state.pagination == .failed(nextPage: 1, error: .temporarilyUnavailable))
        #expect(store.state.projects.count == Self.firstPage.items.count)

        await store.send(.view(.nextPageRetryTapped))
        await store.receive(\.effect.projectsLoadFinished)

        #expect(store.state.projects.count == Self.firstPage.items.count + Self.secondPage.items.count)
        #expect(await fetchLearningProjects.requestedPageSnapshot() == [0, 1, 1])
    }

    @Test
    func `새로고침하면 목록과 다음 페이지 커서를 처음부터 다시 만든다`() async {
        let fetchLearningProjects = HomeLearningProjectsUseCaseMock(results: [
            .success(Self.firstPage),
            .success(Self.secondPage),
            .success(Self.firstPage),
        ])
        let store = makeStore(fetchLearningProjects: fetchLearningProjects)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)
        await store.send(.view(.listBottomReached))
        await store.receive(\.effect.projectsLoadFinished)
        await store.send(.view(.refreshRequested))
        await store.receive(\.effect.projectsLoadFinished)

        #expect(store.state.projects.map(\.projectID) == Self.firstPage.items.map(\.projectID))
        #expect(store.state.pagination == .idle(nextPage: 1))
        #expect(await fetchLearningProjects.requestedPageSnapshot() == [0, 1, 0])
    }

    @Test
    func `다음 페이지에 이미 있는 프로젝트가 오면 중복으로 추가하지 않는다`() async {
        let overlappingPage = LearningProjectPage(
            items: [HomeTestFixture.project(index: 3), HomeTestFixture.project(index: 4)],
            hasNext: false,
        )
        let fetchLearningProjects = HomeLearningProjectsUseCaseMock(
            results: [.success(Self.firstPage), .success(overlappingPage)]
        )
        let store = makeStore(fetchLearningProjects: fetchLearningProjects)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.projectsLoadFinished)
        await store.send(.view(.listBottomReached))
        await store.receive(\.effect.projectsLoadFinished)

        #expect(store.state.projects.map(\.projectID) == [
            "project-0",
            "project-1",
            "project-2",
            "project-3",
            "project-4",
        ])
    }

    // MARK: Private

    private static let firstPage = HomeTestFixture.manyProjectsPage
    private static let secondPage = LearningProjectPage(
        items: [HomeTestFixture.project(index: 4), HomeTestFixture.project(index: 5)],
        hasNext: false,
    )

    private func makeStore(
        mode: ProjectListFeature.Mode = .browsing,
        fetchLearningProjects: HomeLearningProjectsUseCaseMock = HomeLearningProjectsUseCaseMock(
            results: [.success(HomeTestFixture.emptyPage)]
        ),
        deleteLearningProject: StubDeleteLearningProjectUseCase = StubDeleteLearningProjectUseCase(),
        initialLoad: ProjectListFeature.InitialLoad = .idle,
        pagination: ProjectListFeature.Pagination = .idle(nextPage: LearningProjectPage.firstIndex),
    ) -> TestStoreOf<ProjectListFeature> {
        var state = ProjectListFeature.State()
        state.mode = mode
        state.initialLoad = initialLoad
        state.pagination = pagination
        return TestStore(initialState: state) {
            ProjectListFeature(
                fetchLearningProjects: fetchLearningProjects,
                deleteLearningProject: deleteLearningProject,
            )
        }
    }

}
