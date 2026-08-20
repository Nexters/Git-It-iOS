import DomainLearningProject
import Testing

@testable import CompositionAdepter

// MARK: - SampleDeleteLearningProjectTests

@Suite("표본 학습 프로젝트 삭제")
struct SampleDeleteLearningProjectTests {
    @Test
    func `기존 식별자를 삭제하면 다시 삭제할 때 notFound를 던진다`() async throws {
        let project = makeDeleteProject(id: "project-1")
        let store = SampleLearningProjectStore(
            initialPage: .init(items: [project], hasNext: false)
        )
        let deleteProject = SampleDeleteLearningProject(store: store)

        try await deleteProject(projectId: project.projectId)

        await #expect(throws: LearningProjectError.notFound) {
            try await deleteProject(projectId: project.projectId)
        }
    }

    @Test
    func `없는 식별자 삭제는 notFound를 던지고 저장소 상태를 보존한다`() async throws {
        let project = makeDeleteProject(id: "project-1")
        let initialPage = LearningProjectPage(items: [project], hasNext: true)
        let store = SampleLearningProjectStore(initialPage: initialPage)
        let deleteProject = SampleDeleteLearningProject(store: store)
        let fetchProjects = SampleFetchLearningProjects(store: store)

        await #expect(throws: LearningProjectError.notFound) {
            try await deleteProject(projectId: "missing-project")
        }

        #expect(try await fetchProjects(page: 0, size: 1) == initialPage)
    }

    @Test
    func `별도 저장소 인스턴스의 프로세스 수명 상태는 서로 격리된다`() async throws {
        let project = makeDeleteProject(id: "project-1")
        let initialPage = LearningProjectPage(items: [project], hasNext: false)
        let firstStore = SampleLearningProjectStore(initialPage: initialPage)
        let secondStore = SampleLearningProjectStore(initialPage: initialPage)

        try await SampleDeleteLearningProject(store: firstStore)(projectId: project.projectId)

        #expect(try await SampleFetchLearningProjects(store: firstStore)(page: 0, size: 1).items.isEmpty)
        #expect(try await SampleFetchLearningProjects(store: secondStore)(page: 0, size: 1) == initialPage)
    }
}

private func makeDeleteProject(id: String) -> LearningProjectSummary {
    LearningProjectSummary(
        projectId: id,
        repositoryName: "Swift 동시성",
        repositoryImageURL: nil,
        techStack: ["Swift", "TCA"],
        currentSetLabel: "Set 2",
        currentSetTitle: "Actor 이해하기",
        nextSetId: "set-2",
        nextQuestionId: "question-1",
        overallProgressPercent: 50,
    )
}
