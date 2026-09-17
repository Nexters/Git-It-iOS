import Foundation
import Testing

@testable import CompositionApp
@testable import CompositionAuthentication
@testable import DataAuthentication
@testable import DataShared
@testable import DomainAuthentication

// MARK: - SharedLifetimeTests

@Suite("공유 수명 객체", .serialized)
struct SharedLifetimeTests {

    // MARK: Internal

    @Test
    func `같은 보안 저장소를 공유해도 Authentication과 LoginSession의 저장 값이 서로 섞이지 않는다`() async throws {
        let sharedSecureStorage = InMemorySecureValueStorage()
        let authenticationRepository = AuthenticationRepositoryAdapter(
            appleSignInSource: AppleSignInSource(),
            secureStorage: sharedSecureStorage,
        )
        let loginSessionRepository = LoginSessionRepositoryAdapter(
            remote: makeRemote(transport: RecordingRequestTransport(results: [])),
            sessionStorage: sharedSecureStorage,
            appleIdentityStorage: sharedSecureStorage,
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

    private func makeRemote(transport: RecordingRequestTransport) -> AuthenticationRemote {
        AuthenticationRemote(
            baseURL: URL(string: "https://api.git-it.example.com")!,
                transport: transport,
                responseTimeout: RequestClientFactory.defaultResponseTimeout,
            accessTokenProvider: { nil },
        )
    }

}
