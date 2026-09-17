import Foundation
import Testing

@testable import CompositionAuthentication
@testable import DataAuthentication
@testable import DataShared
@testable import DomainAuthentication
@testable import InfrastructureAuthentication

// MARK: - AuthenticationRepositoryAdapterTests

@Suite("AuthenticationRepositoryAdapter", .serialized)
struct AuthenticationRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `저장된 사용자가 없으면 재인증이 필요하다고 판정한다`() async throws {
        let secureStorage = InMemorySecureValueStorage()
        let adapter = AuthenticationRepositoryAdapter(
            authorizationProvider: AppleAuthorizationProvider(),
            credentialStateProvider: AppleCredentialStateProvider(),
            secureStorage: secureStorage,
        )
        try await adapter.clearAuthentication()

        let status = try await adapter.authorizationStatus()

        #expect(status == .reauthenticationRequired)
    }

    @Test
    func `저장된 세션이 없으면 RestoreSessionResult가 unauthenticated다`() async {
        let secureStorage = InMemorySecureValueStorage()
        let authenticationRepository = AuthenticationRepositoryAdapter(
            authorizationProvider: AppleAuthorizationProvider(),
            credentialStateProvider: AppleCredentialStateProvider(),
            secureStorage: secureStorage,
        )
        let loginSessionRepository = LoginSessionRepositoryAdapter(
            remote: makeRemote(transport: RecordingRequestTransport(results: [])),
            sessionStorage: secureStorage,
            appleIdentityStorage: secureStorage,
        )
        let restoreSession = RestoreSession(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )

        let result = await restoreSession()

        #expect(result == .unauthenticated)
    }

    @Test
    func `로그인 세션과 로컬 인증 정리가 모두 성공하면 SignOutResult가 success다`() async throws {
        let secureStorage = InMemorySecureValueStorage()
        try secureStorage.setData(
            Data("apple-user-1".utf8),
            forKey: AppleIdentityStorageLayout.Key.appleUserID.rawValue,
        )
        let transport = RecordingRequestTransport(results: [
            jsonResponse(
                statusCode: 200,
                envelope: #"""
                    {"success":true,"data":{"accessToken":"access-1","refreshToken":"refresh-1","needsCuration":false},"code":null,"message":null,"errors":null}
                    """#,
            )
        ])
        let loginSessionRepository = LoginSessionRepositoryAdapter(
            remote: makeRemote(transport: transport),
            sessionStorage: secureStorage,
            appleIdentityStorage: secureStorage,
        )
        _ = try await loginSessionRepository.start(with: AuthenticationGrant(
            id: .init(rawValue: "id-token-1"),
            method: .apple,
        ))
        let authenticationRepository = AuthenticationRepositoryAdapter(
            authorizationProvider: AppleAuthorizationProvider(),
            credentialStateProvider: AppleCredentialStateProvider(),
            secureStorage: secureStorage,
        )
        let signOut = SignOut(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )

        let result = await signOut()

        #expect(result == .success)
        let restored = try await loginSessionRepository.restore()
        #expect(restored == nil)
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

    private func jsonResponse(
        statusCode: Int,
        envelope: String,
    ) -> TransportResponse {
        TransportResponse(statusCode: statusCode, body: Data(envelope.utf8))
    }

}
