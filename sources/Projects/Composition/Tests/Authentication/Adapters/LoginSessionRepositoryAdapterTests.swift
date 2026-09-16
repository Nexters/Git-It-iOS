import Foundation
import Testing

@testable import CompositionAdapter
@testable import DataAuthentication
@testable import DomainAuthentication
@testable import InfrastructureAuthentication
@testable import InfrastructureNetworkClient

// MARK: - LoginSessionRepositoryAdapterTests

@Suite("LoginSessionRepositoryAdapter", .serialized)
struct LoginSessionRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `로그인 응답을 저장하고 Apple 안정 식별자 기반 사용자를 반환한다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        try keychainStore.save(
            Data("apple-user-1".utf8),
            for: AppleIdentityKeychainLayout.Key.appleUserID.rawValue,
            in: AppleIdentityKeychainLayout.namespace,
        )
        let transport = RecordingHTTPTransport(results: [
            jsonResponse(
                statusCode: 200,
                envelope: #"""
                    {"success":true,"data":{"accessToken":"access-1","refreshToken":"refresh-1","needsCuration":false},"code":null,"message":null,"errors":null}
                    """#,
            )
        ])
        let adapter = LoginSessionRepositoryAdapter(
            remote: makeRemote(transport: transport),
            keychainStore: keychainStore,
        )

        let grant = AuthenticationGrant(id: .init(rawValue: "id-token-1"), method: .apple)
        let user = try await adapter.start(with: grant)

        #expect(user.id == "apple-user-1")
        #expect(user.availability == .available)
        let request = await transport.recordedRequests.first
        #expect(request?.url.path == "/api/v1/auth/login/apple")

        let restored = try await adapter.restore()
        #expect(restored?.id == "apple-user-1")

        try await adapter.signOut()
    }

    @Test
    func `저장된 세션이 없으면 restore가 nil을 반환한다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let adapter = LoginSessionRepositoryAdapter(
            remote: makeRemote(transport: RecordingHTTPTransport(results: [])),
            keychainStore: keychainStore,
        )
        try await adapter.signOut()

        let restored = try await adapter.restore()

        #expect(restored == nil)
    }

    @Test
    func `서버 인증 실패를 Domain 오류로 변환한다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let transport = RecordingHTTPTransport(results: [
            jsonResponse(
                statusCode: 401,
                envelope: #"{"success":false,"data":null,"code":null,"message":"unauthorized","errors":null}"#,
            )
        ])
        let adapter = LoginSessionRepositoryAdapter(
            remote: makeRemote(transport: transport),
            keychainStore: keychainStore,
        )

        await #expect(throws: LoginSessionError.refreshRejectedOrExpired) {
            _ = try await adapter.start(with: AuthenticationGrant(id: .init(rawValue: "id-token-2"), method: .apple))
        }
    }

    @Test
    func `Access Token 확인 실패를 unauthorized로 변환한다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let transport = RecordingHTTPTransport(results: [
            jsonResponse(
                statusCode: 401,
                envelope: #"{"success":false,"data":null,"code":null,"message":"unauthorized","errors":null}"#,
            )
        ])
        let adapter = LoginSessionRepositoryAdapter(
            remote: makeRemote(transport: transport),
            keychainStore: keychainStore,
        )

        await #expect(throws: LoginSessionError.unauthorized) {
            try await adapter.verifyAccessToken()
        }
        let request = await transport.recordedRequests.first
        #expect(request?.url.path == "/api/v1/auth/token")
    }

    // MARK: Private

    private func makeRemote(transport: RecordingHTTPTransport) -> HTTPAuthenticationRemote {
        HTTPAuthenticationRemote(
            client: HTTPClient(
                baseURL: URL(string: "https://api.git-it.example.com")!,
                bodyCoding: StandardJSONBodyCoding(),
                transport: transport,
            ),
            accessTokenProvider: { "stored-access-token" },
        )
    }

    private func jsonResponse(
        statusCode: Int,
        envelope: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data(envelope.utf8))
    }

}
