import DomainLearningProject
import Testing

@testable import CompositionAdepter

// MARK: - SampleFetchLearningProjectsTests

@Suite("표본 학습 프로젝트 조회")
struct SampleFetchLearningProjectsTests {
    @Test
    func `저장소의 초기 페이지를 순서와 다음 페이지 상태까지 그대로 반환한다`() async throws {
        let initialPage = LearningProjectPage(
            items: [
                makeFetchProject(id: "project-1", name: "Swift 동시성"),
                makeFetchProject(id: "project-2", name: "TCA 상태 관리"),
            ],
            hasNext: true,
        )
        let fetchProjects = SampleFetchLearningProjects(
            store: SampleLearningProjectStore(initialPage: initialPage)
        )

        #expect(try await fetchProjects(page: 0, size: 20) == initialPage)
    }

    @Test
    func `같은 저장소에서 삭제한 프로젝트는 다음 조회 결과에서 제외된다`() async throws {
        let deletedProject = makeFetchProject(id: "project-to-delete", name: "삭제할 프로젝트")
        let remainingProject = makeFetchProject(id: "project-to-keep", name: "남길 프로젝트")
        let store = SampleLearningProjectStore(
            initialPage: .init(items: [deletedProject, remainingProject], hasNext: true)
        )
        let fetchProjects = SampleFetchLearningProjects(store: store)
        let deleteProject = SampleDeleteLearningProject(store: store)

        try await deleteProject(projectId: deletedProject.projectId)
        let page = try await fetchProjects(page: 0, size: 20)

        #expect(page.items == [remainingProject])
        #expect(page.hasNext)
    }
}

private func makeFetchProject(
    id: String,
    name: String,
) -> LearningProjectSummary {
    LearningProjectSummary(
        projectId: id,
        repositoryName: name,
        repositoryImageURL: nil,
        techStack: ["Swift", "TCA"],
        currentSetLabel: "Set 2",
        currentSetTitle: "Actor 이해하기",
        nextSetId: "set-2",
        nextQuestionId: "question-1",
        overallProgressPercent: 50,
    )
}
