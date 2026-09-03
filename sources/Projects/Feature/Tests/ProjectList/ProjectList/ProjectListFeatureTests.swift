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
    func `삭제를 확인하기 전에는 삭제를 요청하지 않는다`() async {
        let deleteLearningProject = StubDeleteLearningProjectUseCase()
        let store = makeStore(deleteLearningProject: deleteLearningProject)

        await store.send(.view(.deleteButtonTapped(projectID: "project-0"))) {
            $0.deletion = .confirming(projectID: "project-0")
        }

        #expect(await deleteLearningProject.callCount == 0)
    }

    @Test
    func `삭제를 취소하면 확인 상태를 벗어난다`() async {
        let store = makeStore()

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
    }

    @Test
    func `이미 사라진 프로젝트는 삭제 실패로 남기지 않는다`() async {
        let store = makeStore(
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
    func `행을 누르면 프로젝트 상세를 요청한다`() async {
        let store = makeStore()

        await store.send(.view(.projectRowTapped(projectID: "project-0")))
        await store.receive(\.delegate.projectSelected)
    }

    // MARK: Private

    private func makeStore(
        fetchLearningProjects: HomeLearningProjectsUseCaseMock = HomeLearningProjectsUseCaseMock(
            results: [.success(HomeTestFixture.emptyPage)]
        ),
        deleteLearningProject: StubDeleteLearningProjectUseCase = StubDeleteLearningProjectUseCase(),
    ) -> TestStoreOf<ProjectListFeature> {
        TestStore(initialState: ProjectListFeature.State()) {
            ProjectListFeature(
                fetchLearningProjects: fetchLearningProjects,
                deleteLearningProject: deleteLearningProject,
            )
        }
    }

}
