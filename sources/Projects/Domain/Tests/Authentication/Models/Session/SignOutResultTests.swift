import Testing

@testable import DomainAuthentication

@Suite("SignOutResult")
struct SignOutResultTests {
    @Test
    func `success와 retryableFailure 2케이스만 존재한다`() {
        let results: [SignOutResult] = [.success, .retryableFailure]

        #expect(results[0] == .success)
        #expect(results[1] == .retryableFailure)
        #expect(results[0] != results[1])
    }
}
