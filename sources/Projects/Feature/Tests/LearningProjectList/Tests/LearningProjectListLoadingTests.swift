import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@MainActor
@Suite("학습 프로젝트 목록 로딩")
struct LearningProjectListLoadingTests {

    // MARK: Internal

    @Test
    func `최초 화면 진입은 목록을 한 번만 조회해 loaded로 전이한다`() async {
        let project = makeProject(id: "project-1")
        let page = LearningProjectPage(
            items: [project],
            hasNext: false,
        )
        let fetchProjects = FetchLearningProjectsMock(
            behavior: .result(.success(page))
        )
        let store = TestStore(initialState: LearningProjectListFeature.State()) {
            LearningProjectListFeature(
                fetchLearningProjects: fetchProjects,
                deleteLearningProject: successfulDeleteProjects(),
            )
        }

        await store.send(.onAppear) {
            $0.loadState = .loading
        }
        await store.receive(\.projectsResponse) {
            $0.projects = [project]
            $0.loadState = .loaded
        }
        await store.send(.onAppear)

        #expect(await fetchProjects.snapshot() == [.init(page: 0, size: 20)])
    }

    @Test
    func `완료되지 않은 조회는 loading을 유지하고 취소할 수 있다`() async {
        let fetchProjects = FetchLearningProjectsMock(behavior: .pending)
        let store = TestStore(initialState: LearningProjectListFeature.State()) {
            LearningProjectListFeature(
                fetchLearningProjects: fetchProjects,
                deleteLearningProject: successfulDeleteProjects(),
            )
        }

        let task = await store.send(.onAppear) {
            $0.loadState = .loading
        }
        #expect(await fetchProjects.snapshot() == [.init(page: 0, size: 20)])

        await task.cancel()
        await task.finish()
    }

    @Test
    func `빈 페이지는 loaded와 빈 상태를 함께 표현한다`() async {
        let page = LearningProjectPage(
            items: [],
            hasNext: false,
        )
        let fetchProjects = FetchLearningProjectsMock(
            behavior: .result(.success(page))
        )
        let store = TestStore(initialState: LearningProjectListFeature.State()) {
            LearningProjectListFeature(
                fetchLearningProjects: fetchProjects,
                deleteLearningProject: successfulDeleteProjects(),
            )
        }

        await store.send(.onAppear) {
            $0.loadState = .loading
        }
        await store.receive(\.projectsResponse) {
            $0.loadState = .loaded
        }

        #expect(store.state.isEmpty)
    }

    @Test
    func `조회 실패 뒤 재시도는 loading으로 돌아가 같은 입력으로 다시 조회한다`() async {
        let project = makeProject(id: "retry-project")
        let recoveredPage = LearningProjectPage(
            items: [project],
            hasNext: false,
        )
        let fetchProjects = FetchLearningProjectsMock(
            behavior: .result(.failure(.unexpected))
        )
        let store = TestStore(initialState: LearningProjectListFeature.State()) {
            LearningProjectListFeature(
                fetchLearningProjects: fetchProjects,
                deleteLearningProject: successfulDeleteProjects(),
            )
        }

        await store.send(.onAppear) {
            $0.loadState = .loading
        }
        await store.receive(\.projectsResponse) {
            $0.loadState = .failed
        }

        await fetchProjects.complete(with: .success(recoveredPage))
        await store.send(.retryButtonTapped) {
            $0.loadState = .loading
        }
        await store.receive(\.projectsResponse) {
            $0.projects = [project]
            $0.loadState = .loaded
        }

        #expect(await fetchProjects.snapshot() == [
            .init(page: 0, size: 20),
            .init(page: 0, size: 20),
        ])
    }

    // MARK: Private

    private func successfulDeleteProjects() -> DeleteLearningProjectMock {
        DeleteLearningProjectMock(behavior: .result(.success(())))
    }

    private func makeProject(id: String) -> LearningProjectSummary {
        LearningProjectSummary(
            projectId: id,
            repositoryName: "Git It iOS",
            repositoryImageURL: nil,
            techStack: ["Swift", "SwiftUI", "TCA"],
            currentSetLabel: "Set 2",
            currentSetTitle: "Presentation 구조",
            nextSetId: "set-2",
            nextQuestionId: "question-1",
            overallProgressPercent: 65,
        )
    }

}
