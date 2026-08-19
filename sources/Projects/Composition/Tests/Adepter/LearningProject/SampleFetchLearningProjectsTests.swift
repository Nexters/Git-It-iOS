import DomainLearningProject
import Testing

@testable import Composition

// MARK: - SampleFetchLearningProjectsTests

@Suite("표본 학습 프로젝트 조회")
struct SampleFetchLearningProjectsTests {
    @Test
    func `저장소의 초기 페이지를 순서와 다음 페이지 상태까지 그대로 반환한다`() async throws {
        let firstProject = try makeFetchProject(
            id: "project-1",
            name: "Swift 동시성",
        )
        let secondProject = try makeFetchProject(
            id: "project-2",
            name: "TCA 상태 관리",
        )
        let initialPage = LearningProjectPage(
            projects: [firstProject, secondProject],
            hasNextPage: true,
        )
        let store = SampleLearningProjectStore(initialPage: initialPage)
        let fetchProjects = SampleFetchLearningProjects(store: store)

        let page = try await fetchProjects(page: 0, size: 20)

        #expect(page == initialPage)
    }

    @Test
    func `유효한 최소 page와 size를 별도 정책 없이 받아 저장소 페이지를 반환한다`() async throws {
        let initialPage = LearningProjectPage(
            projects: [],
            hasNextPage: false,
        )
        let store = SampleLearningProjectStore(initialPage: initialPage)
        let fetchProjects = SampleFetchLearningProjects(store: store)

        let page = try await fetchProjects(page: 0, size: 1)

        #expect(page == initialPage)
    }

    @Test
    func `같은 저장소에서 삭제한 프로젝트는 다음 조회 결과에서 제외된다`() async throws {
        let deletedProject = try makeFetchProject(
            id: "project-to-delete",
            name: "삭제할 프로젝트",
        )
        let remainingProject = try makeFetchProject(
            id: "project-to-keep",
            name: "남길 프로젝트",
        )
        let store = SampleLearningProjectStore(
            initialPage: .init(
                projects: [deletedProject, remainingProject],
                hasNextPage: true,
            )
        )
        let fetchProjects = SampleFetchLearningProjects(store: store)
        let deleteProject = SampleDeleteLearningProject(store: store)

        try await deleteProject(deletedProject.id)
        let page = try await fetchProjects(page: 0, size: 20)

        #expect(page.projects == [remainingProject])
        #expect(page.hasNextPage)
    }
}

private func makeFetchProject(
    id: String,
    name: String,
) throws -> LearningProjectSummary {
    LearningProjectSummary(
        id: try #require(LearningProjectID(rawValue: id)),
        name: name,
        technologies: "Swift, TCA",
        progress: .init(completedRatio: 0.5),
        nextSet: .init(order: 2, title: "Actor 이해하기"),
    )
}
