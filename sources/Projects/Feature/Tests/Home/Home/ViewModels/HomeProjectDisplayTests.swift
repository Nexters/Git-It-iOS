import DomainLearningProject
import Testing

@testable import Feature

@Suite("HomeProjectDisplay")
struct HomeProjectDisplayTests {

    @Test
    func `Domain 원문과 순서를 카드 표시 값으로 변환한다`() {
        let displays = HomeTestFixture.manyProjectsPage.items.enumerated()
            .map { HomeProjectDisplay($0.element, index: $0.offset) }

        #expect(displays.map(\.title) == ["Repository 0", "Repository 1", "Repository 2", "Repository 3"])
        #expect(displays[0].technologies == "Swift · SwiftUI · TCA")
        #expect(displays[0].currentSetLabel == "Sprint Beta 0")
        #expect(displays[3].progress == 1.4)
        #expect(displays.map(\.variant) == [.purple, .lightBlue, .darkBlue, .purple])
    }

    @Test
    func `학습 ID가 모두 있을 때만 학습을 시작할 수 있다`() {
        let valid = HomeProjectDisplay(HomeTestFixture.project(index: 1), index: 1)
        let invalid = HomeProjectDisplay(HomeTestFixture.project(index: 2, hasLearningIDs: false), index: 2)

        #expect(valid.isLearningEnabled)
        #expect(!invalid.isLearningEnabled)
        #expect(valid.projectID == "project-1")
    }

    @Test
    func `긴 표시 값도 원문을 축약 모델로 바꾸지 않는다`() {
        let longName = String(repeating: "긴 프로젝트 이름", count: 12)
        let project = HomeTestFixture.project(index: 0)
        let replaced = LearningProjectSummary(
            projectID: project.projectID,
            repositoryName: longName,
            repositoryImageURL: project.repositoryImageURL,
            techStack: project.techStack,
            currentSetLabel: project.currentSetLabel,
            currentSetTitle: project.currentSetTitle,
            nextSetID: project.nextSetID,
            nextQuestionID: project.nextQuestionID,
            overallProgressPercent: project.overallProgressPercent,
        )

        #expect(HomeProjectDisplay(replaced, index: 0).title == longName)
    }

}
