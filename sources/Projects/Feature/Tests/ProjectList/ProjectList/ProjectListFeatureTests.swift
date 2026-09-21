import ComposableArchitecture
import DomainProject
import Testing

@testable import Feature

@MainActor
@Suite("ProjectListFeature 프로젝트 목록")
struct ProjectListFeatureTests {

    // MARK: Internal

    @Test
    func `진입하면 스트림이 준 목록으로 채운다`() async {
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.manyProjectsPage)
        let store = makeStore(projects: projects)
        store.exhaustivity = .off

        let task = await store.send(.view(.task))
        await store.receive(\.projectSummaries.effect.projectsReceived)

        #expect(store.state.projectSummaries.load == .loaded(HomeTestFixture.manyProjectsPage))
        #expect(store.state.projects.count == HomeTestFixture.manyProjectsPage.summaries.count)
        #expect(store.state.hasNextPage)

        await projects.finish()
        await task.cancel()
    }

    @Test
    func `갱신에 실패하면 실패 상태를 남긴다`() async {
        let projects = ProjectUseCaseMock(refreshResults: [.failure(.temporarilyUnavailable)])
        let store = makeStore(projects: projects)
        store.exhaustivity = .off

        let task = await store.send(.view(.task))
        await store.receive(\.projectSummaries.effect.refreshFinished)

        #expect(store.state.projectSummaries.load == .failed(.temporarilyUnavailable))

        await projects.finish()
        await task.cancel()
    }

    @Test
    func `목록이 갱신되면 페이지네이션을 다시 설정한다`() async {
        var state = loadedState(list: HomeTestFixture.oneProjectPage)
        state.pagination.pagination = .failed(.temporarilyUnavailable)
        let store = makeStore(state: state)

        await store.send(.projectSummaries(.delegate(.listUpdated(HomeTestFixture.manyProjectsPage))))
        await store.receive(.pagination(.input(.listReplaced(hasNextPage: true)))) {
            $0.pagination.hasNextPage = true
            $0.pagination.pagination = .idle
        }
    }

    @Test
    func `행을 누르면 프로젝트 상세를 요청한다`() async {
        let store = makeStore()

        await store.send(.view(.projectRowTapped(projectID: "project-0")))
        await store.receive(\.delegate.projectSelected)
    }

    @Test
    func `재생 버튼은 다음 세트로 이어하기를 요청한다`() async {
        let store = makeStore(state: loadedState())

        await store.send(.view(.learningTapped(projectID: "project-1")))
        await store.receive(.delegate(.learningRequested(projectID: "project-1", nextSetID: "set-1")))
    }

    @Test
    func `다음 문제가 없는 프로젝트는 이어하기를 요청하지 않는다`() async {
        let list = ProjectList(
            summaries: [HomeTestFixture.project(index: 0, hasLearningIDs: false)],
            hasNextPage: false,
            isLoaded: true,
        )
        let store = makeStore(state: loadedState(list: list))

        await store.send(.view(.learningTapped(projectID: "project-0")))
    }

    @Test
    func `삭제 모드에서는 재생 버튼이 이어하기를 요청하지 않는다`() async {
        let store = makeStore(state: loadedState(mode: .deleting))

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
        let store = makeStore(state: state(mode: .menuPresented))

        await store.send(.view(.menuDismissed)) {
            $0.mode = .browsing
        }
    }

    @Test
    func `메뉴에서 프로젝트 삭제를 고르면 삭제 모드가 된다`() async {
        let store = makeStore(state: state(mode: .menuPresented))

        await store.send(.view(.deletionMenuItemTapped)) {
            $0.mode = .deleting
        }
    }

    @Test
    func `삭제 모드에서 뒤로 가면 목록 모드로 돌아온다`() async {
        let store = makeStore(state: state(mode: .deleting))

        await store.send(.view(.backTapped)) {
            $0.mode = .browsing
        }
        await store.receive(.deletion(.input(.cancel)))
    }

    @Test
    func `목록 모드에서는 삭제 확인이 시작되지 않는다`() async {
        let deleteProject = ProjectUseCaseDeletionStub()
        let store = makeStore(deleteProject: deleteProject)

        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))

        #expect(await deleteProject.callCount == 0)
    }

    @Test
    func `삭제 모드에서는 행을 눌러도 상세로 이동하지 않는다`() async {
        let store = makeStore(state: state(mode: .deleting))

        await store.send(.view(.projectRowTapped(projectID: "project-0")))
    }

    @Test
    func `삭제 모드의 삭제 버튼은 삭제에 request를 보내고 확인 전에는 삭제를 요청하지 않는다`() async {
        let deleteProject = ProjectUseCaseDeletionStub()
        let store = makeStore(deleteProject: deleteProject, state: state(mode: .deleting))

        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))
        await store.receive(.deletion(.input(.request("project-0")))) {
            $0.deletion.deletion = .confirming(projectID: "project-0")
        }

        #expect(await deleteProject.callCount == 0)
    }

    @Test
    func `삭제 취소는 삭제에 cancel을 보낸다`() async {
        let store = makeStore(state: state(mode: .deleting))

        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))
        await store.receive(.deletion(.input(.request("project-0")))) {
            $0.deletion.deletion = .confirming(projectID: "project-0")
        }
        await store.send(.view(.deletionCancelled))
        await store.receive(.deletion(.input(.cancel))) {
            $0.deletion.deletion = .idle
        }
    }

    @Test
    func `삭제 실패 뒤에도 다시 삭제를 요청할 수 있다`() async {
        var state = loadedState(mode: .deleting)
        state.deletion.deletion = .failed(projectID: "project-0", error: .temporarilyUnavailable)
        let store = makeStore(state: state)

        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))
        await store.receive(.deletion(.input(.request("project-0")))) {
            $0.deletion.deletion = .confirming(projectID: "project-0")
        }
    }

    @Test
    func `삭제에 성공하면 목록에서 그 프로젝트를 지운다`() async {
        let store = makeStore(
            deleteProject: ProjectUseCaseDeletionStub(),
            state: loadedState(mode: .deleting),
        )
        store.exhaustivity = .off

        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.deletion.effect.deletionFinished)
        await store.receive(.delegate(.projectDeleted))

        #expect(!store.state.projects.contains { $0.id == "project-0" })
        #expect(store.state.deletion.deletion == .idle)
        #expect(store.state.mode == .deleting)
    }

    @Test
    func `이미 사라진 프로젝트는 삭제 실패로 남기지 않는다`() async {
        let store = makeStore(
            deleteProject: ProjectUseCaseDeletionStub(results: [.failure(.notFound)]),
            state: loadedState(mode: .deleting),
        )
        store.exhaustivity = .off

        await store.send(.view(.deleteButtonTapped(projectID: "project-1")))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.deletion.effect.deletionFinished)
        await store.receive(\.projectSummaries.delegate.listUpdated)

        #expect(!store.state.projects.contains { $0.id == "project-1" })
        #expect(store.state.deletion.deletion == .idle)
    }

    @Test
    func `마지막 프로젝트를 지우면 삭제 모드를 벗어난다`() async {
        let store = makeStore(
            deleteProject: ProjectUseCaseDeletionStub(),
            state: loadedState(mode: .deleting),
        )
        store.exhaustivity = .off

        for projectID in store.state.projects.map(\.id) {
            await store.send(.view(.deleteButtonTapped(projectID: projectID)))
            await store.send(.view(.deletionConfirmed))
            await store.receive(\.deletion.effect.deletionFinished)
            await store.receive(\.projectSummaries.delegate.listUpdated)
        }

        #expect(store.state.projects.isEmpty)
        #expect(store.state.mode == .browsing)
    }

    @Test
    func `삭제 실패는 목록과 삭제 모드를 유지한다`() async {
        let store = makeStore(
            deleteProject: ProjectUseCaseDeletionStub(results: [.failure(.temporarilyUnavailable)]),
            state: loadedState(mode: .deleting),
        )
        store.exhaustivity = .off

        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.deletion.effect.deletionFinished)

        #expect(store.state.projects.contains { $0.id == "project-0" })
        #expect(store.state.mode == .deleting)
        #expect(store.state.deletion.deletion == .failed(projectID: "project-0", error: .temporarilyUnavailable))
    }

    @Test
    func `삭제 실패 후에도 뒤로 가면 목록 모드로 돌아온다`() async {
        let store = makeStore(
            deleteProject: ProjectUseCaseDeletionStub(results: [.failure(.temporarilyUnavailable)]),
            state: loadedState(mode: .deleting),
        )
        store.exhaustivity = .off

        await store.send(.view(.deleteButtonTapped(projectID: "project-0")))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.deletion.effect.deletionFinished)

        await store.send(.view(.backTapped)) {
            $0.mode = .browsing
        }
        await store.receive(.deletion(.input(.cancel))) {
            $0.deletion.deletion = .idle
        }
    }

    @Test
    func `목록 끝에 닿으면 다음 페이지를 한 번 요청한다`() async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(projects: projects, state: loadedState())
        store.exhaustivity = .off

        await store.send(.view(.listBottomReached))
        await store.receive(.pagination(.input(.nextPageRequested)))
        await store.receive(\.pagination.effect.nextPageFinished)

        #expect(store.state.pagination.pagination == .idle)
        #expect(await projects.snapshot().nextPageCallCount == 1)
    }

    @Test
    func `다음 페이지가 없으면 목록 끝에 닿아도 요청하지 않는다`() async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(projects: projects, state: loadedState(list: HomeTestFixture.oneProjectPage))

        await store.send(.view(.listBottomReached))

        #expect(store.state.pagination.pagination == .exhausted)
        #expect(await projects.snapshot().nextPageCallCount == 0)
    }

    @Test
    func `첫 조회 전에는 목록 끝에 닿아도 다음 페이지를 요청하지 않는다`() async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(projects: projects)

        await store.send(.view(.listBottomReached))

        #expect(await projects.snapshot().nextPageCallCount == 0)
    }

    @Test
    func `다음 페이지 조회에 실패하면 재시도로 다시 요청한다`() async {
        let projects = ProjectUseCaseMock(
            nextPageResults: [.failure(.temporarilyUnavailable), .success(())]
        )
        let store = makeStore(projects: projects, state: loadedState())
        store.exhaustivity = .off

        await store.send(.view(.listBottomReached))
        await store.receive(\.pagination.effect.nextPageFinished)
        #expect(store.state.pagination.pagination == .failed(.temporarilyUnavailable))

        await store.send(.view(.nextPageRetryTapped))
        await store.receive(.pagination(.input(.retry)))
        await store.receive(\.pagination.effect.nextPageFinished)

        #expect(store.state.pagination.pagination == .idle)
        #expect(await projects.snapshot().nextPageCallCount == 2)
    }

    @Test
    func `새로고침 입력은 목록에 refresh를 보낸다`() async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(projects: projects, state: loadedState())
        store.exhaustivity = .off

        await store.send(.view(.refreshRequested))
        await store.receive(.pagination(.input(.refreshStarted)))
        await store.receive(\.projectSummaries.effect.refreshFinished)

        #expect(store.state.projectSummaries.requestID == 1)
        #expect(await projects.snapshot().refreshCallCount == 1)
    }

    // MARK: Private

    private func state(mode: ProjectListFeature.Mode) -> ProjectListFeature.State {
        var state = ProjectListFeature.State()
        state.mode = mode
        return state
    }

    private func loadedState(
        list: ProjectList = HomeTestFixture.manyProjectsPage,
        mode: ProjectListFeature.Mode = .browsing,
    ) -> ProjectListFeature.State {
        var state = ProjectListFeature.State()
        state.projectSummaries.load = .loaded(list)
        state.pagination = ProjectListPaginationFeature.State(
            pagination: list.hasNextPage ? .idle : .exhausted,
            hasNextPage: list.hasNextPage,
        )
        state.mode = mode
        return state
    }

    private func makeStore(
        projects: ProjectUseCaseMock = ProjectUseCaseMock(),
        deleteProject: ProjectUseCaseDeletionStub = ProjectUseCaseDeletionStub(),
        state: ProjectListFeature.State = ProjectListFeature.State(),
    ) -> TestStoreOf<ProjectListFeature> {
        TestStore(initialState: state) {
            ProjectListFeature(
                projects: { await projects.projects() },
                refreshProjects: { try await projects.refresh() },
                requestNextPage: { try await projects.requestNextPage() },
                deleteProject: deleteProject.deleteProject,
            )
        }
    }

}
