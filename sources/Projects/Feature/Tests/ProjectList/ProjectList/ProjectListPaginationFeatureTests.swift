import ComposableArchitecture
import DomainProject
import Testing

@testable import Feature

@MainActor
@Suite("ProjectListPaginationFeature 다음 페이지 조회")
struct ProjectListPaginationFeatureTests {

    // MARK: Internal

    @Test(arguments: [
        (true, ProjectListPaginationFeature.State.Pagination.idle),
        (false, .exhausted),
    ])
    func `대기 상태의 nextPageRequested는 다음 페이지를 요청하고 다음 페이지 여부로 결과 상태를 정한다`(
        hasNextPage: Bool,
        expected: ProjectListPaginationFeature.State.Pagination,
    ) async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(
            state: ProjectListPaginationFeature.State(pagination: .idle, hasNextPage: hasNextPage),
            projects: projects,
        )

        await store.send(.input(.nextPageRequested)) {
            $0.pagination = .loading
        }
        await store.receive(.effect(.nextPageFinished(error: nil))) {
            $0.pagination = expected
        }

        #expect(await projects.snapshot().nextPageCallCount == 1)
    }

    @Test(arguments: [
        ProjectListPaginationFeature.State.Pagination.loading,
        .failed(.temporarilyUnavailable),
        .exhausted,
    ])
    func `대기 상태가 아니면 nextPageRequested를 무시한다`(
        pagination: ProjectListPaginationFeature.State.Pagination
    ) async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(
            state: ProjectListPaginationFeature.State(pagination: pagination, hasNextPage: true),
            projects: projects,
        )

        await store.send(.input(.nextPageRequested))

        #expect(await projects.snapshot().nextPageCallCount == 0)
    }

    @Test
    func `다음 페이지 조회 실패는 실패 상태로 남긴다`() async {
        let store = makeStore(
            state: ProjectListPaginationFeature.State(pagination: .idle, hasNextPage: true),
            projects: ProjectUseCaseMock(nextPageResults: [.failure(.temporarilyUnavailable)]),
        )

        await store.send(.input(.nextPageRequested)) {
            $0.pagination = .loading
        }
        await store.receive(.effect(.nextPageFinished(error: .temporarilyUnavailable))) {
            $0.pagination = .failed(.temporarilyUnavailable)
        }
    }

    @Test
    func `실패 상태의 retry는 다음 페이지를 다시 요청한다`() async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(
            state: ProjectListPaginationFeature.State(pagination: .failed(.temporarilyUnavailable), hasNextPage: true),
            projects: projects,
        )

        await store.send(.input(.retry)) {
            $0.pagination = .loading
        }
        await store.receive(.effect(.nextPageFinished(error: nil))) {
            $0.pagination = .idle
        }

        #expect(await projects.snapshot().nextPageCallCount == 1)
    }

    @Test
    func `실패 상태가 아니면 retry를 무시한다`() async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(
            state: ProjectListPaginationFeature.State(pagination: .idle, hasNextPage: true),
            projects: projects,
        )

        await store.send(.input(.retry))

        #expect(await projects.snapshot().nextPageCallCount == 0)
    }

    @Test(arguments: [
        (true, ProjectListPaginationFeature.State.Pagination.idle),
        (false, .exhausted),
    ])
    func `listReplaced는 다음 페이지 여부를 저장하고 페이지네이션을 다시 설정한다`(
        hasNextPage: Bool,
        expected: ProjectListPaginationFeature.State.Pagination,
    ) async {
        let store = makeStore(
            state: ProjectListPaginationFeature.State(pagination: .failed(.temporarilyUnavailable), hasNextPage: !hasNextPage)
        )

        await store.send(.input(.listReplaced(hasNextPage: hasNextPage))) {
            $0.hasNextPage = hasNextPage
            $0.pagination = expected
        }
    }

    @Test
    func `refreshStarted는 진행 중인 다음 페이지 요청을 취소한다`() async {
        let store = TestStore(
            initialState: ProjectListPaginationFeature.State(pagination: .idle, hasNextPage: true)
        ) {
            ProjectListPaginationFeature(requestNextPage: { try await Task.never() })
        }

        await store.send(.input(.nextPageRequested)) {
            $0.pagination = .loading
        }
        await store.send(.input(.refreshStarted))
        await store.finish()
    }

    @Test
    func `조회 중이 아닐 때 도착한 결과는 반영하지 않는다`() async {
        let store = makeStore(
            state: ProjectListPaginationFeature.State(pagination: .exhausted, hasNextPage: false)
        )

        await store.send(.effect(.nextPageFinished(error: .temporarilyUnavailable)))
    }

    // MARK: Private

    private func makeStore(
        state: ProjectListPaginationFeature.State,
        projects: ProjectUseCaseMock = ProjectUseCaseMock(),
    ) -> TestStoreOf<ProjectListPaginationFeature> {
        TestStore(initialState: state) {
            ProjectListPaginationFeature(requestNextPage: { try await projects.requestNextPage() })
        }
    }

}
