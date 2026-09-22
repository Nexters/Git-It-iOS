import ComposableArchitecture
import DomainProject
import Foundation
import Testing

@testable import Feature

@MainActor
@Suite("ProjectSummaryListFeature 프로젝트 요약 목록")
struct ProjectSummaryListFeatureTests {

    // MARK: Internal

    @Test
    func `start는 목록 관찰을 시작하고 새로고침한다`() async {
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        let store = makeStore(projects: projects)
        store.exhaustivity = .off

        let task = await store.send(.input(.start))

        #expect(store.state.load == .loading)
        #expect(store.state.requestID == 1)

        await store.receive(\.effect.projectsReceived)
        await store.receive(\.delegate.listUpdated)

        #expect(store.state.load == .loaded(HomeTestFixture.oneProjectPage))
        #expect(await projects.snapshot().refreshCallCount == 1)

        await projects.finish()
        await task.cancel()
    }

    @Test
    func `조회 완료가 아니면 refresh는 로딩을 세운다`() async {
        let store = makeStore()

        await store.send(.input(.refresh)) {
            $0.load = .loading
            $0.requestID = 1
        }
        await store.receive(.effect(.refreshFinished(
            requestID: 1,
            error: nil,
        )))
    }

    @Test
    func `이미 로드된 빈 목록의 새로고침은 전체 로딩을 다시 세우지 않는다`() async {
        let store = makeStore(state: ProjectSummaryListFeature.State(load: .loaded(HomeTestFixture.emptyPage)))

        await store.send(.input(.refresh)) {
            $0.requestID = 1
        }
        await store.receive(.effect(.refreshFinished(
            requestID: 1,
            error: nil,
        )))

        #expect(store.state.load == .loaded(HomeTestFixture.emptyPage))
    }

    @Test
    func `로드되지 않은 목록 수신은 상태를 바꾸지 않는다`() async {
        let store = makeStore(state: ProjectSummaryListFeature.State(load: .loading))

        await store.send(.effect(.projectsReceived(ProjectList(
            summaries: [],
            hasNextPage: false,
            isLoaded: false,
        ))))
    }

    @Test
    func `로드된 목록 수신은 조회 완료 상태로 바꾸고 listUpdated를 보낸다`() async {
        let store = makeStore(state: ProjectSummaryListFeature.State(load: .loading))

        await store.send(.effect(.projectsReceived(HomeTestFixture.manyProjectsPage))) {
            $0.load = .loaded(HomeTestFixture.manyProjectsPage)
        }
        await store.receive(.delegate(.listUpdated(HomeTestFixture.manyProjectsPage)))
    }

    @Test
    func `조회 완료 뒤 새로고침 실패는 목록을 유지한다`() async {
        var state = ProjectSummaryListFeature.State(load: .loaded(HomeTestFixture.oneProjectPage))
        state.requestID = 1
        let store = makeStore(state: state)

        await store.send(.effect(.refreshFinished(
            requestID: 1,
            error: .temporarilyUnavailable,
        )))

        #expect(store.state.load == .loaded(HomeTestFixture.oneProjectPage))
    }

    @Test
    func `조회 완료 전 새로고침 실패는 실패 상태가 된다`() async {
        var state = ProjectSummaryListFeature.State(load: .loading)
        state.requestID = 1
        let store = makeStore(state: state)

        await store.send(.effect(.refreshFinished(
            requestID: 1,
            error: .temporarilyUnavailable,
        ))) {
            $0.load = .failed(.temporarilyUnavailable)
        }
    }

    @Test
    func `현재 request ID와 다른 새로고침 결과는 무시한다`() async {
        var state = ProjectSummaryListFeature.State(load: .loading)
        state.requestID = 2
        let store = makeStore(state: state)

        await store.send(.effect(.refreshFinished(
            requestID: 1,
            error: .temporarilyUnavailable,
        )))

        #expect(store.state.load == .loading)
    }

    @Test
    func `ProjectError가 아닌 새로고침 오류는 unexpected로 바꾼다`() async {
        let store = makeStore(refreshProjects: { throw URLError(.badServerResponse) })

        await store.send(.input(.refresh)) {
            $0.load = .loading
            $0.requestID = 1
        }
        await store.receive(.effect(.refreshFinished(
            requestID: 1,
            error: .unexpected,
        ))) {
            $0.load = .failed(.unexpected)
        }
    }

    @Test
    func `projectRemoved는 해당 행을 제거하고 listUpdated를 보낸다`() async {
        let remaining = ProjectList(
            summaries: Array(HomeTestFixture.manyProjectsPage.summaries.dropFirst()),
            hasNextPage: HomeTestFixture.manyProjectsPage.hasNextPage,
            isLoaded: true,
        )
        let store = makeStore(state: ProjectSummaryListFeature.State(load: .loaded(HomeTestFixture.manyProjectsPage)))

        await store.send(.input(.projectRemoved("project-0"))) {
            $0.load = .loaded(remaining)
        }
        await store.receive(.delegate(.listUpdated(remaining)))
    }

    @Test
    func `조회 완료가 아니면 projectRemoved는 무시한다`() async {
        let store = makeStore(state: ProjectSummaryListFeature.State(load: .loading))

        await store.send(.input(.projectRemoved("project-0")))
    }

    // MARK: Private

    private func makeStore(
        state: ProjectSummaryListFeature.State = ProjectSummaryListFeature.State(),
        refreshProjects: @escaping @Sendable () async throws -> Void = { },
    ) -> TestStoreOf<ProjectSummaryListFeature> {
        TestStore(initialState: state) {
            ProjectSummaryListFeature(
                projects: { AsyncStream { $0.finish() } },
                refreshProjects: refreshProjects,
            )
        }
    }

    private func makeStore(projects: ProjectUseCaseMock) -> TestStoreOf<ProjectSummaryListFeature> {
        TestStore(initialState: ProjectSummaryListFeature.State()) {
            ProjectSummaryListFeature(
                projects: { await projects.projects() },
                refreshProjects: { try await projects.refresh() },
            )
        }
    }

}
