import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

// MARK: - LearningProjectListDependencyIsolationTests

@MainActor
@Suite("학습 프로젝트 목록 의존성 격리")
struct LearningProjectListDependencyIsolationTests {

    // MARK: Internal

    @Test
    func `다른 Protocol 구현을 주입해도 조회 상태 전이와 입력 검증이 유지된다`() async {
        let project = makeProject(id: "alternate-project")
        let page = LearningProjectPage(
            items: [project],
            hasNext: true,
        )
        let fetchProjects = AlternateFetchLearningProjects(page: page)
        let store = TestStore(initialState: LearningProjectListFeature.State()) {
            LearningProjectListFeature(
                fetchLearningProjects: fetchProjects,
                deleteLearningProject: AlternateDeleteLearningProject(),
            )
        }

        await store.send(.onAppear) {
            $0.loadState = .loading
        }
        await store.receive(\.projectsResponse) {
            $0.projects = [project]
            $0.loadState = .loaded
        }

        #expect(await fetchProjects.snapshot() == [.init(page: 0, size: 20)])
    }

    @Test
    func `다른 Protocol 구현을 주입해도 삭제 상태 전이와 식별자 검증이 유지된다`() async {
        let project = makeProject(id: "alternate-project")
        let deleteProjects = AlternateDeleteLearningProject()
        let store = TestStore(
            initialState: LearningProjectListFeature.State(
                projects: [project],
                loadState: .loaded,
                isDeleteMode: true,
                pendingDeletion: project.projectId,
            )
        ) {
            LearningProjectListFeature(
                fetchLearningProjects: AlternateFetchLearningProjects(
                    page: .init(items: [project], hasNext: false)
                ),
                deleteLearningProject: deleteProjects,
            )
        }

        await store.send(.deletionConfirmed)
        await store.receive(\.deletionResponse) {
            $0.projects.removeAll { $0.projectId == project.projectId }
            $0.pendingDeletion = nil
            $0.isDeleteMode = false
        }

        #expect(await deleteProjects.snapshot() == [project.projectId])
    }

    // MARK: Private

    private func makeProject(id: String) -> LearningProjectSummary {
        LearningProjectSummary(
            projectId: id,
            repositoryName: "대체 구현 프로젝트",
            repositoryImageURL: nil,
            techStack: ["Swift"],
            currentSetLabel: "Set 1",
            currentSetTitle: "의존성 격리",
            nextSetId: "set-1",
            nextQuestionId: "question-1",
            overallProgressPercent: 50,
        )
    }

}

// MARK: - AlternateFetchLearningProjects

private actor AlternateFetchLearningProjects: FetchLearningProjectsUseCase {

    // MARK: Lifecycle

    init(page: LearningProjectPage) {
        self.page = page
    }

    // MARK: Internal

    struct Call: Sendable, Equatable {
        let page: Int
        let size: Int
    }

    func callAsFunction(
        page: Int,
        size: Int,
    ) async throws -> LearningProjectPage {
        calls.append(.init(page: page, size: size))
        return self.page
    }

    func snapshot() -> [Call] {
        calls
    }

    // MARK: Private

    private let page: LearningProjectPage
    private var calls = [Call]()

}

// MARK: - AlternateDeleteLearningProject

private actor AlternateDeleteLearningProject: DeleteLearningProjectUseCase {

    // MARK: Internal

    func callAsFunction(projectId: String) async throws {
        projectIDs.append(projectId)
    }

    func snapshot() -> [String] {
        projectIDs
    }

    // MARK: Private

    private var projectIDs = [String]()

}
