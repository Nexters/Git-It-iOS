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

    @Test
    func `AuthenticationOutcome과 케이스 집합이 다르다`() {
        let outcomeFieldNames = Set(
            Mirror(reflecting: AuthenticationOutcome.recoverableFailure).children.compactMap(\.label)
        )
        let resultFieldNames = Set(Mirror(reflecting: SignOutResult.retryableFailure).children.compactMap(\.label))

        #expect(outcomeFieldNames == resultFieldNames)
        #expect(type(of: AuthenticationOutcome.recoverableFailure) != type(of: SignOutResult.retryableFailure))
    }
}
