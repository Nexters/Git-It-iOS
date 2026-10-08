import ComposableArchitecture
import DomainProject
import Testing

@testable import Feature

@MainActor
@Suite("ProjectDetailLoadFeature 상세 조회")
struct ProjectDetailLoadFeatureTests {

    // MARK: Internal

    @Test
    func `load는 조회 중으로 바꾸고 성공 결과를 상세로 남긴다`() async {
        let projectDetail = ProjectUseCaseDetailStub(results: [.success(ProjectDetailTestFixture.mixedProgressDetail)])
        let store = makeStore(projectDetail: projectDetail)

        await store.send(.input(.load)) {
            $0.loadStatus = .loading
            $0.requestID = 1
        }
        await store.receive(.effect(.detailLoadFinished(
            requestID: 1,
            result: .success(ProjectDetailTestFixture.mixedProgressDetail),
        ))) {
            $0.detail = ProjectDetailTestFixture.mixedProgressDetail
            $0.loadStatus = .loaded
        }

        #expect(await projectDetail.callCount == 1)
    }

    @Test
    func `이미 조회한 상세가 있어도 load는 무조건 조회 중으로 바꾼다`() async {
        var state = ProjectDetailLoadFeature.State(projectID: ProjectDetailTestFixture.projectID)
        state.detail = ProjectDetailTestFixture.mixedProgressDetail
        state.loadStatus = .loaded
        let store = makeStore(
            projectDetail: ProjectUseCaseDetailStub(results: [.success(ProjectDetailTestFixture.completedDetail)]),
            state: state,
        )

        await store.send(.input(.load)) {
            $0.loadStatus = .loading
            $0.requestID = 1
        }
        await store.receive(.effect(.detailLoadFinished(
            requestID: 1,
            result: .success(ProjectDetailTestFixture.completedDetail),
        ))) {
            $0.detail = ProjectDetailTestFixture.completedDetail
            $0.loadStatus = .loaded
        }
    }

    @Test
    func `조회에 실패하면 오류 의미를 보존한다`() async {
        let store = makeStore(
            projectDetail: ProjectUseCaseDetailStub(results: [.failure(.temporarilyUnavailable)])
        )

        await store.send(.input(.load)) {
            $0.loadStatus = .loading
            $0.requestID = 1
        }
        await store.receive(.effect(.detailLoadFinished(
            requestID: 1,
            result: .failure(.temporarilyUnavailable),
        ))) {
            $0.loadStatus = .failed(.temporarilyUnavailable)
        }
    }

    @Test
    func `현재 request ID와 다른 결과는 상태를 바꾸지 않는다`() async {
        var state = ProjectDetailLoadFeature.State(projectID: ProjectDetailTestFixture.projectID)
        state.requestID = 2
        state.loadStatus = .loading
        let store = makeStore(state: state)

        await store.send(.effect(.detailLoadFinished(
            requestID: 1,
            result: .success(ProjectDetailTestFixture.mixedProgressDetail),
        )))
    }

    @Test
    func `첫 미완료 세트와 시작 가능 여부는 상세에서 파생한다`() {
        var state = ProjectDetailLoadFeature.State(projectID: ProjectDetailTestFixture.projectID)
        #expect(state.firstIncompleteSet == nil)
        #expect(!state.isResumeEnabled)
        #expect(!state.isEmpty)

        state.detail = ProjectDetailTestFixture.mixedProgressDetail
        #expect(state.firstIncompleteSet?.setID == "set-1")
        #expect(state.isResumeEnabled)
        #expect(!state.isEmpty)

        state.detail = ProjectDetailTestFixture.completedDetail
        #expect(state.firstIncompleteSet == nil)
        #expect(!state.isResumeEnabled)

        state.detail = ProjectDetailTestFixture.emptyDetail
        #expect(state.isEmpty)
    }

    // MARK: Private

    private func makeStore(
        projectDetail: ProjectUseCaseDetailStub = ProjectUseCaseDetailStub(
            results: [.success(ProjectDetailTestFixture.mixedProgressDetail)]
        ),
        state: ProjectDetailLoadFeature.State = ProjectDetailLoadFeature.State(projectID: ProjectDetailTestFixture.projectID),
    ) -> TestStoreOf<ProjectDetailLoadFeature> {
        TestStore(initialState: state) {
            ProjectDetailLoadFeature(projectDetail: projectDetail.projectDetail)
        }
    }

}
