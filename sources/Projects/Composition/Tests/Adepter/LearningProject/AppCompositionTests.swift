import Testing

import CompositionAdepter
import DomainLearningProject

// MARK: - AppCompositionTests

@Suite("AppComposition 조립")
struct AppCompositionTests {

    // MARK: Internal

    @Test
    func `sample은 두 Use Case가 공유하는 프로세스 수명 상태를 제공한다`() async throws {
        let composition = AppComposition.sample()
        let initialPage = try await composition.fetchLearningProjects(page: 0, size: 20)
        let deletedID = try #require(initialPage.items.first?.projectId)

        try await composition.deleteLearningProject(projectId: deletedID)
        let updatedPage = try await composition.fetchLearningProjects(page: 0, size: 20)

        #expect(updatedPage.items.count == initialPage.items.count - 1)
        #expect(!updatedPage.items.contains { $0.projectId == deletedID })
    }

    @Test
    func `projects 표본은 페이지를 그대로 반환한다`() async throws {
        let expectedPage = LearningProjectPage(
            items: [project(id: "project-1")],
            hasNext: true,
        )
        let composition = AppComposition.sample(fetch: .projects(expectedPage))

        let page = try await composition.fetchLearningProjects(page: 0, size: 1)

        #expect(page == expectedPage)
    }

    @Test
    func `failure 표본은 unexpected 오류를 반환한다`() async {
        let composition = AppComposition.sample(fetch: .failure)

        await #expect(throws: LearningProjectError.unexpected) {
            try await composition.fetchLearningProjects(page: 0, size: 20)
        }
    }

    @Test
    func `pending 표본은 완료되지 않고 Task 취소를 전파한다`() async {
        let composition = AppComposition.sample(fetch: .pending)
        let pending = Task {
            try await composition.fetchLearningProjects(page: 0, size: 20)
        }

        await Task.yield()
        pending.cancel()

        await #expect(throws: CancellationError.self) {
            try await pending.value
        }
    }

    @Test
    func `public initializer로 두 Use Case 실행 객체를 대체한다`() async throws {
        let expectedPage = LearningProjectPage(
            items: [project(id: "substitute-project")],
            hasNext: false,
        )
        let deletionRecorder = DeletionRecorder()
        let composition = AppComposition(
            fetchLearningProjects: SubstituteFetchLearningProjects(page: expectedPage),
            deleteLearningProject: SubstituteDeleteLearningProject(recorder: deletionRecorder),
        )
        let deletedID = try #require(expectedPage.items.first?.projectId)

        let page = try await composition.fetchLearningProjects(page: 3, size: 7)
        try await composition.deleteLearningProject(projectId: deletedID)

        #expect(page == expectedPage)
        #expect(await deletionRecorder.snapshot() == deletedID)
    }

    // MARK: Private

    private func project(id: String) -> LearningProjectSummary {
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

// MARK: - SubstituteFetchLearningProjects

private struct SubstituteFetchLearningProjects: FetchLearningProjectsUseCase {
    let page: LearningProjectPage

    func callAsFunction(
        page _: Int,
        size _: Int,
    ) async throws -> LearningProjectPage {
        page
    }
}

// MARK: - SubstituteDeleteLearningProject

private struct SubstituteDeleteLearningProject: DeleteLearningProjectUseCase {
    let recorder: DeletionRecorder

    func callAsFunction(projectId: String) async throws {
        await recorder.record(projectId)
    }
}

// MARK: - DeletionRecorder

private actor DeletionRecorder {

    // MARK: Internal

    func record(_ projectId: String) {
        deletedID = projectId
    }

    func snapshot() -> String? {
        deletedID
    }

    // MARK: Private

    private var deletedID: String?

}
