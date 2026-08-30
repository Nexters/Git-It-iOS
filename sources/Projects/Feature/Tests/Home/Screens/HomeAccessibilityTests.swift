import DomainLearningProject
import Testing

@testable import Feature

@Suite("Home 접근성 표시")
struct HomeAccessibilityTests {
    @Test
    func `프로필 보조 문구는 존재하는 값만 조합한다`() {
        #expect(HomeScreen.Display.profileSubtitle(HomeTestFixture.profileWithBoth) == "iOS · 주니어")
        #expect(HomeScreen.Display.profileSubtitle(HomeTestFixture.profileWithPosition) == "Back-end")
        #expect(HomeScreen.Display.profileSubtitle(HomeTestFixture.profileWithCareer) == "미들")
        #expect(HomeScreen.Display.profileSubtitle(HomeTestFixture.profileWithNameOnly) == nil)
    }

    @Test
    func `기본 avatar와 주요 control의 접근성 문구를 제공한다`() {
        #expect(HomeScreen.Display.usesDefaultAvatar)
        #expect(HomeScreen.Display.registrationLabel == "프로젝트 지금 불러오기")
        #expect(HomeScreen.Display.showAllLabel == "학습 중인 레포지토리 전체 보기")
        #expect(HomeScreen.Display.disabledLearningHint == "다음 학습 위치가 없습니다")
    }

    @Test
    func `긴 표시 값도 원문을 축약 모델로 바꾸지 않는다`() {
        let longName = String(repeating: "긴 프로젝트 이름", count: 12)
        let project = HomeTestFixture.project(index: 0)
        let replaced = DomainLearningProject.LearningProjectSummary(
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

        #expect(HomeScreen.Display.project(replaced, index: 0).title == longName)
    }
}
