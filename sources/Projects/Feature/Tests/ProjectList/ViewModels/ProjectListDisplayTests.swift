import DomainLearningProject
import Testing

@testable import Feature

@Suite("ProjectListDisplay 표시 값")
struct ProjectListDisplayTests {
    @Test
    func `기술 스택을 가운뎃점으로 이어 붙인다`() {
        let display = ProjectListDisplay.list(projects: [HomeTestFixture.project(index: 0)])

        #expect(display.first?.supportingText == "Swift · SwiftUI · TCA")
    }

    @Test
    func `진행률 퍼센트를 0에서 1 사이 비율로 옮긴다`() {
        let display = ProjectListDisplay.list(projects: [HomeTestFixture.project(index: 2)])

        #expect(display.first?.progress == 0.5)
    }

    @Test
    func `세트 라벨의 숫자를 세트 번호로 읽는다`() {
        let display = ProjectListDisplay.list(projects: [HomeTestFixture.project(index: 3)])

        #expect(display.first?.currentSet == 3)
    }

    @Test
    func `세트 라벨에 숫자가 없으면 1번 세트로 둔다`() {
        let project = LearningProjectSummary(
            projectID: "project-x",
            repositoryName: "Repository X",
            repositoryImageURL: nil,
            techStack: [],
            currentSetLabel: "시작하기",
            currentSetTitle: "개요",
            nextSetID: nil,
            nextQuestionID: nil,
            overallProgressPercent: 0,
        )

        #expect(ProjectListDisplay.list(projects: [project]).first?.currentSet == 1)
    }
}
