import Testing

@testable import DataLearningProject

@Suite("Data 학습 프로젝트 오류")
struct DataLearningProjectErrorTests {

    @Test
    func `공급자 중립 실패 의미를 10개로 구분한다`() {
        #expect(DataLearningProjectError.allCases == [
            .invalidRequest,
            .unauthorized,
            .temporarilyUnavailable,
            .transport,
            .decoding,
            .unexpectedStatus,
            .projectUnavailable,
            .questionUnavailable,
            .learningSetUnavailable,
            .generationRetryUnavailable,
        ])
    }

    @Test(arguments: [
        (404, "PROJECT-001", DataLearningProjectError.projectUnavailable),
        (404, "QUIZ-005", DataLearningProjectError.questionUnavailable),
        (404, "QUIZ-006", DataLearningProjectError.learningSetUnavailable),
        (409, "QUIZ-007", DataLearningProjectError.generationRetryUnavailable),
    ])
    func `대표 서버 오류 코드를 매핑한다`(httpStatus: Int, code: String, expected: DataLearningProjectError) {
        let serverError = ServerAPIError(httpStatus: httpStatus, code: code, message: nil, fieldErrors: nil)

        #expect(DataLearningProjectError(from: serverError) == expected)
    }

}
