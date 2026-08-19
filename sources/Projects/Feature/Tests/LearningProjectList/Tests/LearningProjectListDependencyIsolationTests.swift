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
    func `다른 Protocol 구현을 주입해도 조회 상태 전이와 입력 검증이 유지된다`() async throws {
        let project = try makeProject(id: "alternate-project")
        let page = LearningProjectPage(
            projects: [project],
            hasNextPage: true,
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
            $0.projects = .init(uniqueElements: [project])
            $0.loadState = .loaded
        }

        #expect(await fetchProjects.snapshot() == [.init(page: 0, size: 20)])
    }

    @Test
    func `다른 Protocol 구현을 주입해도 삭제 상태 전이와 식별자 검증이 유지된다`() async throws {
        let project = try makeProject(id: "alternate-project")
        let deleteProjects = AlternateDeleteLearningProject()
        let store = TestStore(
            initialState: LearningProjectListFeature.State(
                projects: .init(uniqueElements: [project]),
                loadState: .loaded,
                isDeleteMode: true,
                pendingDeletion: project.id,
            )
        ) {
            LearningProjectListFeature(
                fetchLearningProjects: AlternateFetchLearningProjects(
                    page: .init(projects: [project], hasNextPage: false)
                ),
                deleteLearningProject: deleteProjects,
            )
        }

        await store.send(.deletionConfirmed)
        await store.receive(\.deletionResponse) {
            $0.projects.remove(id: project.id)
            $0.pendingDeletion = nil
            $0.isDeleteMode = false
        }

        #expect(await deleteProjects.snapshot() == [project.id])
    }

    // MARK: Private

    private func makeProject(id: String) throws -> LearningProjectSummary {
        LearningProjectSummary(
            id: try #require(LearningProjectID(rawValue: id)),
            name: "대체 구현 프로젝트",
            technologies: "Swift",
            progress: .init(completedRatio: 0.5),
            nextSet: .init(order: 1, title: "의존성 격리"),
        )
    }

}

// MARK: - AlternateFetchLearningProjects

private actor AlternateFetchLearningProjects: FetchLearningProjects {

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

private actor AlternateDeleteLearningProject: DeleteLearningProject {

    // MARK: Internal

    func callAsFunction(_ id: LearningProjectID) async throws {
        projectIDs.append(id)
    }

    func snapshot() -> [LearningProjectID] {
        projectIDs
    }

    // MARK: Private

    private var projectIDs = [LearningProjectID]()

}
