import Testing

@testable import DomainAuthentication

@Suite("SignInResult")
struct SignInResultTests {
    @Test
    func `success cancelled retryableFailure는 서로 다른 케이스다`() {
        let user = AuthenticatedUser(id: "user-1", availability: .available, displayName: nil)
        let success = SignInResult.success(user, needsCuration: true)
        let cancelled = SignInResult.cancelled
        let retryableFailure = SignInResult.retryableFailure

        #expect(success != cancelled)
        #expect(cancelled != retryableFailure)
        #expect(success != retryableFailure)
    }

    @Test
    func `needsCuration true false를 손실 없이 보존한다`() {
        let user = AuthenticatedUser(id: "user-1", availability: .available, displayName: nil)
        let needsCuration = SignInResult.success(user, needsCuration: true)
        let noCuration = SignInResult.success(user, needsCuration: false)

        guard case .success(_, let needsCurationValue) = needsCuration else {
            Issue.record("success 케이스여야 한다")
            return
        }
        guard case .success(_, let noCurationValue) = noCuration else {
            Issue.record("success 케이스여야 한다")
            return
        }

        #expect(needsCurationValue == true)
        #expect(noCurationValue == false)
        #expect(needsCuration != noCuration)
    }
}
