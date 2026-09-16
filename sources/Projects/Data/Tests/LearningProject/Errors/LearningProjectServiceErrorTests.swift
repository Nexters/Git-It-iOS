import Testing

@testable import DataLearningProject

@Suite("Data 학습 프로젝트 오류")
struct LearningProjectServiceErrorTests {

    @Test
    func `공급자 중립 실패 의미를 8개로 구분한다`() {
        #expect(LearningProjectServiceError.allCases == [
            .invalidRequest,
            .unauthorized,
            .temporarilyUnavailable,
            .transport,
            .unexpectedStatus,
            .projectUnavailable,
            .questionUnavailable,
            .learningSetUnavailable,
        ])
    }

    @Test(arguments: [
        (404, "PROJECT-001", LearningProjectServiceError.projectUnavailable),
        (404, "QUIZ-005", LearningProjectServiceError.questionUnavailable),
        (404, "QUIZ-006", LearningProjectServiceError.learningSetUnavailable),
        (409, "QUIZ-007", LearningProjectServiceError.unexpectedStatus),
    ])
    func `대표 서버 오류 코드를 매핑한다`(httpStatus: Int, code: String, expected: LearningProjectServiceError) {
        let serverError = ServerAPIError(httpStatus: httpStatus, code: code, message: nil, fieldErrors: nil)

        #expect(LearningProjectServiceError(from: serverError) == expected)
    }

}
