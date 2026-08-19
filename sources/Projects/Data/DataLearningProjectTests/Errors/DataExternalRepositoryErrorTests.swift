import Testing

@testable import DataLearningProject

@Suite("외부 Repository Data 오류")
struct DataExternalRepositoryErrorTests {
    @Test
    func `오프라인과 그 밖의 오류를 구분한다`() {
        #expect(DataExternalRepositoryError.allCases == [.offline, .other])
        #expect(DataExternalRepositoryError.offline != .other)
    }
}
