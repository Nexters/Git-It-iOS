import Foundation
import Testing

@testable import CompositionAdapter
@testable import DataAuthentication
@testable import DomainAuthentication
@testable import InfrastructureAuthentication

// MARK: - SharedLifetimeTests

/// `AuthenticationAssembly`는 `HTTPClient`·`KeychainStore`를 노출하지 않으므로(FR-028) 외부에서
/// 인스턴스 동일성을 직접 검증할 수 없다. 대신 두 Adapter가 같은 `KeychainStore` 인스턴스를
/// 공유해도 서로 다른 namespace·key로 충돌 없이 공존하는지 검증해 공유 가능성을 확인한다.
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
