import Testing

@testable import DomainAuthentication

@Suite("RestoreSessionResult")
struct RestoreSessionResultTests {
    @Test
    func `authenticated unauthenticated recoverableFailure 3케이스를 갖는다`() {
        let user = AuthenticatedUser(id: "user-1", availability: .available, displayName: nil)
        let results: [RestoreSessionResult] = [.authenticated(user), .unauthenticated, .recoverableFailure]

        #expect(results[0] == .authenticated(user))
        #expect(results[1] == .unauthenticated)
        #expect(results[2] == .recoverableFailure)
    }
}
