import Testing

@testable import Feature

@Suite("Home 프로젝트 표시 변환")
struct HomeProjectPresentationTests {
    @Test
    func `Domain 원문과 순서를 카드 표시 값으로 변환한다`() {
        let presentations = HomeScreen.Display.projects(HomeTestFixture.manyProjectsPage.items)

        #expect(presentations.map(\.title) == ["Repository 0", "Repository 1", "Repository 2", "Repository 3"])
        #expect(presentations[0].technologies == "Swift · SwiftUI · TCA")
        #expect(presentations[0].currentSetLabel == "Sprint Beta 0")
        #expect(presentations[3].progress == 1.4)
        #expect(presentations.map(\.variant) == [.purple, .lightBlue, .darkBlue, .purple])
    }

    @Test
    func `학습 ID가 모두 있을 때만 학습 intent payload를 만든다`() {
        let valid = HomeScreen.Display.project(HomeTestFixture.project(index: 1), index: 1)
        let invalid = HomeScreen.Display.project(HomeTestFixture.project(index: 2, hasLearningIDs: false), index: 2)

        #expect(valid.learningIntent == .init(projectID: "project-1", nextSetID: "set-1", nextQuestionID: "question-1"))
        #expect(invalid.learningIntent == nil)
        #expect(valid.projectID == "project-1")
    }
}
