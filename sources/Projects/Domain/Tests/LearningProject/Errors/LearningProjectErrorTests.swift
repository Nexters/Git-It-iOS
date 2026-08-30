import Testing

@testable import DomainLearningProject

@Suite("학습 프로젝트 오류")
struct LearningProjectErrorTests {
    @Test
    func `잘못된 요청과 미인증 및 미존재 및 그 밖의 오류를 구분한다`() {
        #expect(
            LearningProjectError.allCases == [
                .invalidRequest,
                .unauthorized,
                .notFound,
                .learningSetUnavailable,
                .questionUnavailable,
                .temporarilyUnavailable,
                .unexpected,
            ]
        )
    }
}
