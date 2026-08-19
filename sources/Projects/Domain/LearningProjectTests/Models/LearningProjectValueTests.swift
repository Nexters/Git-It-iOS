import Testing

@testable import DomainLearningProject

@Suite("학습 프로젝트 값 객체")
struct LearningProjectValueTests {
    @Test
    func `식별자는 공백뿐인 원시값을 거부하고 원래 값을 보존한다`() throws {
        #expect(LearningProjectID(rawValue: "") == nil)
        #expect(LearningProjectID(rawValue: " \n\t") == nil)

        let id = try #require(LearningProjectID(rawValue: "  project-1  "))

        #expect(id.rawValue == "  project-1  ")
        #expect(id.id == id)
    }

    @Test
    func `진행률은 0부터 1 사이로 고정한다`() {
        #expect(LearningProgress(completedRatio: -0.1).completedRatio == 0)
        #expect(LearningProgress(completedRatio: 0.4).completedRatio == 0.4)
        #expect(LearningProgress(completedRatio: 1.1).completedRatio == 1)
    }

    @Test
    func `세트 순서는 1 이상으로 고정하고 제목을 보존한다`() {
        let firstSet = LearningSetMark(order: 0, title: "시작하기")
        let laterSet = LearningSetMark(order: 3, title: "의존성 이해하기")

        #expect(firstSet.order == 1)
        #expect(firstSet.title == "시작하기")
        #expect(laterSet.order == 3)
        #expect(laterSet.title == "의존성 이해하기")
    }
}
