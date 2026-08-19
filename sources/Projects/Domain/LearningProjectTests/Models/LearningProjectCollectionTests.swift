import Testing

@testable import DomainLearningProject

@Suite("학습 프로젝트 목록 모델")
struct LearningProjectCollectionTests {
    @Test
    func `요약 모델은 식별 가능하며 목록 표시 값을 보존한다`() throws {
        let id = try #require(LearningProjectID(rawValue: "project-1"))
        let summary = LearningProjectSummary(
            id: id,
            name: "Swift 동시성",
            technologies: "Swift, TCA",
            progress: .init(completedRatio: 0.5),
            nextSet: .init(order: 2, title: "Actor 이해하기"),
        )

        #expect(summary.id == id)
        #expect(summary.name == "Swift 동시성")
        #expect(summary.technologies == "Swift, TCA")
        #expect(summary.progress == LearningProgress(completedRatio: 0.5))
        #expect(summary.nextSet == LearningSetMark(order: 2, title: "Actor 이해하기"))
    }

    @Test
    func `페이지는 프로젝트 항목과 다음 페이지 상태를 보존한다`() throws {
        let project = LearningProjectSummary(
            id: try #require(LearningProjectID(rawValue: "project-1")),
            name: "Swift 동시성",
            technologies: "Swift",
            progress: .init(completedRatio: 0.25),
            nextSet: .init(order: 1, title: "시작하기"),
        )
        let page = LearningProjectPage(
            projects: [project],
            hasNextPage: true,
        )

        #expect(page.projects == [project])
        #expect(page.hasNextPage)
    }
}
