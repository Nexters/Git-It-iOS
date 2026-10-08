import Testing

@testable import DataExternalRepository

@Suite("Data 외부 Repository 오류")
struct ExternalRepositoryFetchErrorTests {
    @Test
    func `연결 실패와 그 밖의 실패만 구분한다`() {
        #expect(ExternalRepositoryFetchError.allCases == [.offline, .other])
        #expect(ExternalRepositoryFetchError.offline != .other)
    }
}
