import Testing

@testable import DataExternalRepository

@Suite("Data 외부 Repository 오류")
struct DataExternalRepositoryErrorTests {
    @Test
    func `연결 실패와 그 밖의 실패만 구분한다`() {
        #expect(DataExternalRepositoryError.allCases == [.offline, .other])
        #expect(DataExternalRepositoryError.offline != .other)
    }
}
