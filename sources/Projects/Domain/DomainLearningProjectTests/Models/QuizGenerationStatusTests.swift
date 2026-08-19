import Testing

@testable import DomainLearningProject

@Suite("퀴즈 생성 상태")
struct QuizGenerationStatusTests {
    @Test
    func `등록부터 학습 가능까지 여섯 단계를 구분한다`() {
        #expect(
            QuizGenerationStatus.allCases == [
                .ready,
                .analyzed,
                .anchored,
                .rejected,
                .failed,
                .completed,
            ]
        )
    }
}
