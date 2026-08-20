import Testing

@testable import DataLearningProject

@Suite("학습 프로젝트 Data 오류")
struct DataLearningProjectErrorTests {
    @Test
    func `서버 오류 코드에 대응하는 다섯 케이스를 구분한다`() {
        #expect(
            DataLearningProjectError.allCases == [
                .invalidRequest,
                .unauthorized,
                .notFound,
                .serverError,
                .unexpected,
            ]
        )
    }
}
