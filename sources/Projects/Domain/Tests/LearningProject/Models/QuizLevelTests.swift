import Testing

@testable import DomainLearningProject

@Suite("퀴즈 난이도")
struct QuizLevelTests {
    @Test
    func `세 가지 깊이 수준을 구분한다`() {
        #expect(QuizLevel.allCases == [.l1, .l2, .l3])
        #expect(QuizLevel.l1 != .l2)
        #expect(QuizLevel.l2 != .l3)
    }
}
