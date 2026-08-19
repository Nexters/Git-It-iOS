import Testing

@testable import DomainLearningProject

@Suite("외부 Repository 조회 오류")
struct ExternalRepositoryErrorTests {
    @Test
    func `URL 형식 오류와 오프라인 및 그 밖의 오류를 구분한다`() {
        #expect(ExternalRepositoryError.allCases == [.invalidURLFormat, .offline, .other])
        #expect(ExternalRepositoryError.invalidURLFormat != .offline)
        #expect(ExternalRepositoryError.offline != .other)
    }
}
