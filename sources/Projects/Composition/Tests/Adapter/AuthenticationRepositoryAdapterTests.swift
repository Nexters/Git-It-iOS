import Foundation
import Testing

@testable import CompositionAdapter
@testable import DataAuthentication
@testable import DomainAuthentication
@testable import InfrastructureAuthentication

// MARK: - AuthenticationRepositoryAdapterTests

/// `AuthenticationRepositoryAdapter`·`LoginSessionRepositoryAdapter`가 `SignIn`·`SignOut`·
/// `RestoreSession`(Domain)과 조합됐을 때 신규 액션 결과 타입을 손실 없이 전달하는지 검증한다.
/// `authenticate()`·실제 `authorizationStatus()` 승인 경로는 `AppleAuthorizationProvider`·
/// `AppleCredentialStateProvider`가 실기기 Apple ID 상태에 결합돼 있어 이 계층에서 결정적으로
/// 재현할 수 없다(`SignInResult.cancelled`/`.retryableFailure`와 `RestoreSessionResult`의
/// `.authenticated`/`.recoverableFailure` 분기는 Domain `SignInTests`·`RestoreSessionTests`가
/// 완전히 mock된 `AuthenticationRepository`로 이미 검증한다). 이 파일은 keychain만으로 결정적으로
/// 재현 가능한 `.unauthenticated`·`.success` 경로를 다룬다.
@Suite("AuthenticationRepositoryAdapter", .serialized)
struct AuthenticationRepositoryAdapterTests {

    @Test
    func `저장된 사용자가 없으면 재인증이 필요하다고 판정한다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let adapter = AuthenticationRepositoryAdapter(
            authorizationProvider: AppleAuthorizationProvider(),
            credentialStateProvider: AppleCredentialStateProvider(),
            keychainStore: keychainStore,
        )
        try await adapter.clearAuthentication()

        let status = try await adapter.authorizationStatus()

        #expect(status == .reauthenticationRequired)
    }

    @Test
    func `저장된 세션이 없으면 RestoreSessionResult가 unauthenticated다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let authenticationRepository = AuthenticationRepositoryAdapter(
            authorizationProvider: AppleAuthorizationProvider(),
            credentialStateProvider: AppleCredentialStateProvider(),
            keychainStore: keychainStore,
        )
        let loginSessionRepository = LoginSessionRepositoryAdapter(
            remote: StubAuthenticationRemote(),
            keychainStore: keychainStore,
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
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        try keychainStore.save(
            Data("apple-user-1".utf8),
            for: AppleIdentityKeychainLayout.Key.appleUserID.rawValue,
            in: AppleIdentityKeychainLayout.namespace,
        )
        let remote = StubAuthenticationRemote(appleLoginResult: .success(
            LoginResponseDTO(accessToken: "access-1", refreshToken: "refresh-1", needsCuration: false)
        ))
        let loginSessionRepository = LoginSessionRepositoryAdapter(remote: remote, keychainStore: keychainStore)
        _ = try await loginSessionRepository.start(with: AuthenticationGrant(
            id: .init(rawValue: "id-token-1"),
            method: .apple,
        ))
        let authenticationRepository = AuthenticationRepositoryAdapter(
            authorizationProvider: AppleAuthorizationProvider(),
            credentialStateProvider: AppleCredentialStateProvider(),
            keychainStore: keychainStore,
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
