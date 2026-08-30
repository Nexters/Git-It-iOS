import Foundation
import Testing
@testable import CompositionAdapter
@testable import DataAuthentication
@testable import DomainAuthentication
@testable import InfrastructureAuthentication

// MARK: - LoginSessionRepositoryAdapterTests

@Suite("LoginSessionRepositoryAdapter", .serialized)
struct LoginSessionRepositoryAdapterTests {

    @Test
    func `로그인 응답을 저장하고 Apple 안정 식별자 기반 사용자를 반환한다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        try keychainStore.save(
            Data("apple-user-1".utf8),
            for: AppleIdentityKeychainLayout.Key.appleUserID.rawValue,
            in: AppleIdentityKeychainLayout.namespace,
        )
        let remote = StubAuthenticationRemote(appleLoginResult: .success(
            LoginResponseDTO(accessToken: "access-1", refreshToken: "refresh-1", needsCuration: false)
        ))
        let adapter = LoginSessionRepositoryAdapter(remote: remote, keychainStore: keychainStore)

        let grant = AuthenticationGrant(id: .init(rawValue: "id-token-1"), method: .apple)
        let user = try await adapter.start(with: grant)

        #expect(user.id == "apple-user-1")
        #expect(user.availability == .available)

        let restored = try await adapter.restore()
        #expect(restored?.id == "apple-user-1")

        try await adapter.signOut()
    }

    @Test
    func `저장된 세션이 없으면 restore가 nil을 반환한다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let adapter = LoginSessionRepositoryAdapter(remote: StubAuthenticationRemote(), keychainStore: keychainStore)
        try await adapter.signOut()

        let restored = try await adapter.restore()

        #expect(restored == nil)
    }

    @Test
    func `서버 인증 실패를 Domain 오류로 변환한다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let remote = StubAuthenticationRemote(appleLoginResult: .failure(.unauthorized))
        let adapter = LoginSessionRepositoryAdapter(remote: remote, keychainStore: keychainStore)

        await #expect(throws: LoginSessionError.refreshRejectedOrExpired) {
            _ = try await adapter.start(with: AuthenticationGrant(id: .init(rawValue: "id-token-2"), method: .apple))
        }
    }

}

// MARK: - StubAuthenticationRemote

private actor StubAuthenticationRemote: AuthenticationRemote {

    // MARK: Lifecycle

    init(
        appleLoginResult: Result<LoginResponseDTO, DataAuthenticationError> = .failure(.unexpectedStatus),
        verifyAccessTokenResult: Result<Void, DataAuthenticationError> = .success(()),
    ) {
        self.appleLoginResult = appleLoginResult
        self.verifyAccessTokenResult = verifyAccessTokenResult
    }

    // MARK: Internal

    func appleLogin(idToken _: String) async throws -> LoginResponseDTO {
        try appleLoginResult.get()
    }

    func verifyAccessToken() async throws {
        try verifyAccessTokenResult.get()
    }

    // MARK: Private

    private let appleLoginResult: Result<LoginResponseDTO, DataAuthenticationError>
    private let verifyAccessTokenResult: Result<Void, DataAuthenticationError>

}
