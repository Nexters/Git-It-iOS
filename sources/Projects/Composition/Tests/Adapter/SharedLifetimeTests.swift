import Foundation
import Testing

@testable import CompositionAdapter
@testable import DataAuthentication
@testable import DomainAuthentication
@testable import InfrastructureAuthentication

// MARK: - SharedLifetimeTests

@Suite("공유 수명 객체", .serialized)
struct SharedLifetimeTests {

    @Test
    func `같은 KeychainStore를 공유해도 Authentication과 LoginSession의 저장 값이 서로 섞이지 않는다`() async throws {
        let sharedKeychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let authenticationRepository = AuthenticationRepositoryAdapter(
            authorizationProvider: AppleAuthorizationProvider(),
            credentialStateProvider: AppleCredentialStateProvider(),
            keychainStore: sharedKeychainStore,
        )
        let loginSessionRepository = LoginSessionRepositoryAdapter(
            remote: StubAuthenticationRemote(),
            keychainStore: sharedKeychainStore,
        )

        try await authenticationRepository.clearAuthentication()
        try await loginSessionRepository.signOut()

        let restoredBeforeLogin = try await loginSessionRepository.restore()
        let statusBeforeLogin = try await authenticationRepository.authorizationStatus()

        #expect(restoredBeforeLogin == nil)
        #expect(statusBeforeLogin == .reauthenticationRequired)

        try await authenticationRepository.clearAuthentication()
        try await loginSessionRepository.signOut()
    }

}

// MARK: - StubAuthenticationRemote

private actor StubAuthenticationRemote: AuthenticationRemote {
    func appleLogin(idToken _: String) async throws -> LoginResponseDTO {
        throw DataAuthenticationError.unexpectedStatus
    }

    func verifyAccessToken() async throws { }
}
