import Testing

import CompositionAdepter
import DomainLearningProject

// MARK: - AppCompositionTests

@Suite("AppComposition 조립")
struct AppCompositionTests {

    // MARK: Internal

    @Test
    func `live는 두 Use Case가 공유하는 프로세스 수명 상태를 제공한다`() async throws {
        let composition = AppComposition.live()
        let fetchLearningProjects: any FetchLearningProjects = composition.fetchLearningProjects
        let deleteLearningProject: any DeleteLearningProject = composition.deleteLearningProject
        let initialPage = try await fetchLearningProjects(page: 0, size: 20)
        let deletedID = try #require(initialPage.projects.first?.id)

        try await deleteLearningProject(deletedID)
        let updatedPage = try await fetchLearningProjects(page: 0, size: 20)

        #expect(updatedPage.projects.count == initialPage.projects.count - 1)
        #expect(!updatedPage.projects.contains { $0.id == deletedID })
    }

    @Test
    func `projects 표본은 항목이 있는 페이지를 그대로 반환한다`() async throws {
        let expectedPage = LearningProjectPage(
            projects: [try project(id: "project-1")],
            hasNextPage: true,
        )
        let composition = AppComposition.sample(fetch: .projects(expectedPage))

        let page = try await composition.fetchLearningProjects(page: 0, size: 1)

        #expect(page == expectedPage)
    }

    @Test
    func `projects 표본은 빈 페이지를 그대로 반환한다`() async throws {
        let expectedPage = LearningProjectPage(
            projects: [],
            hasNextPage: false,
        )
        let composition = AppComposition.sample(fetch: .projects(expectedPage))

        let page = try await composition.fetchLearningProjects(page: 0, size: 20)

        #expect(page == expectedPage)
    }

    @Test
    func `failure 표본은 일시적 사용 불가 오류를 반환한다`() async {
        let composition = AppComposition.sample(fetch: .failure)

        await #expect(throws: LearningProjectError.temporarilyUnavailable) {
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
            projects: [try project(id: "substitute-project")],
            hasNextPage: false,
        )
        let deletionRecorder = DeletionRecorder()
        let composition = AppComposition(
            fetchLearningProjects: SubstituteFetchLearningProjects(page: expectedPage),
            deleteLearningProject: SubstituteDeleteLearningProject(recorder: deletionRecorder),
        )
        let deletedID = try #require(expectedPage.projects.first?.id)

        let page = try await composition.fetchLearningProjects(page: 3, size: 7)
        try await composition.deleteLearningProject(deletedID)

        #expect(page == expectedPage)
        #expect(await deletionRecorder.snapshot() == deletedID)
    }

    // MARK: Private

    private func project(id: String) throws -> LearningProjectSummary {
        LearningProjectSummary(
            id: try #require(LearningProjectID(rawValue: id)),
            name: "Git It iOS",
            technologies: "Swift · SwiftUI · TCA",
            progress: .init(completedRatio: 0.65),
            nextSet: .init(order: 2, title: "Presentation 구조"),
        )
    }

}

// MARK: - SubstituteFetchLearningProjects

private struct SubstituteFetchLearningProjects: FetchLearningProjects {
    let page: LearningProjectPage

    func callAsFunction(
        page _: Int,
        size _: Int,
    ) async throws -> LearningProjectPage {
        page
    }
}

// MARK: - SubstituteDeleteLearningProject

private struct SubstituteDeleteLearningProject: DeleteLearningProject {
    let recorder: DeletionRecorder

    func callAsFunction(_ id: LearningProjectID) async throws {
        await recorder.record(id)
    }
}

// MARK: - DeletionRecorder

private actor DeletionRecorder {

    // MARK: Internal

    func record(_ id: LearningProjectID) {
        deletedID = id
    }

    func snapshot() -> LearningProjectID? {
        deletedID
    }

    // MARK: Private

    private var deletedID: LearningProjectID?

}
