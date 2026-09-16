import Foundation
import Testing

@testable import CompositionApp
@testable import CompositionAuthentication
@testable import DataAuthentication
@testable import DomainAuthentication
@testable import InfrastructureAuthentication
@testable import InfrastructureNetworkClient

// MARK: - SharedLifetimeTests

@Suite("공유 수명 객체", .serialized)
struct SharedLifetimeTests {

    // MARK: Internal

    @Test
    func `같은 KeychainStore를 공유해도 Authentication과 LoginSession의 저장 값이 서로 섞이지 않는다`() async throws {
        let sharedKeychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let authenticationRepository = AuthenticationRepositoryAdapter(
            authorizationProvider: AppleAuthorizationProvider(),
            credentialStateProvider: AppleCredentialStateProvider(),
            keychainStore: sharedKeychainStore,
        )
        let loginSessionRepository = LoginSessionRepositoryAdapter(
            remote: makeRemote(transport: RecordingHTTPTransport(results: [])),
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

    // MARK: Private

    private func makeRemote(transport: RecordingHTTPTransport) -> HTTPAuthenticationRemote {
        HTTPAuthenticationRemote(
            client: HTTPClient(
                baseURL: URL(string: "https://api.git-it.example.com")!,
                bodyCoding: StandardJSONBodyCoding(),
                transport: transport,
            ),
            accessTokenProvider: { nil },
        )
    }

}
