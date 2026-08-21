import DataAuthentication
import DataMember
import DomainAuthentication
import DomainMember
import Foundation
import InfrastructureAuthentication
import InfrastructureNetworkClient

// MARK: - AuthenticationAssembly

public struct AuthenticationAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        keychainStore: KeychainStore = KeychainStore(),
        transport: (any HTTPTransport)? = nil,
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
    ) {
        let accessTokenProvider: @Sendable () async -> String? = {
            (try? SessionRecordKeychainCoding(keychainStore: keychainStore).load())?.tokens.accessToken
        }
        let client = makeHTTPClient(baseURL: baseURL, responseTimeout: responseTimeout, transport: transport)
        let authenticationRemote = HTTPAuthenticationRemote(
            client: client,
            accessTokenProvider: accessTokenProvider,
        )
        let authenticationRepository = AuthenticationRepositoryAdapter(
            authorizationProvider: AppleAuthorizationProvider(),
            credentialStateProvider: AppleCredentialStateProvider(),
            keychainStore: keychainStore,
        )
        let loginSessionRepository = LoginSessionRepositoryAdapter(
            remote: authenticationRemote,
            keychainStore: keychainStore,
        )
        let curationRepository = CurationRepositoryAdapter(
            remote: MemberRepositoryAdapter(
                remote: HTTPMemberRemote(client: client, accessTokenProvider: accessTokenProvider)
            ),
            loginSessionRepository: loginSessionRepository,
        )

        signIn = SignIn(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )
        signOut = SignOut(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )
        restoreSession = RestoreSession(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )
        observeAuthenticationOutcomes = ObserveAuthenticationOutcomes(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )
        // UC12(refresh)·UC14(revoke)는 서버 capability 미확보(INT-API-001)로 구조만 조립한다.
        refreshSession = RefreshSession(loginSessionRepository: loginSessionRepository)
        verifyAccessToken = VerifyAccessToken(loginSessionRepository: loginSessionRepository)
        completeCuration = CompleteCuration(repository: curationRepository)
        self.loginSessionRepository = loginSessionRepository
    }

    // MARK: Public

    public let signIn: any SignInUseCase
    public let signOut: any SignOutUseCase
    public let restoreSession: any RestoreSessionUseCase
    public let observeAuthenticationOutcomes: any ObserveAuthenticationOutcomesUseCase
    public let refreshSession: any RefreshSessionUseCase
    public let verifyAccessToken: any VerifyAccessTokenUseCase
    public let completeCuration: any CompleteCurationUseCase

    // MARK: Internal

    /// `AppComposition`이 다른 조립체(예: `MemberAssembly`의 curation 조정)와 세션 상태를
    /// 공유하기 위해 사용하는 non-public 참조입니다. public API 표면(any XxxUseCase)에는
    /// 포함되지 않습니다.
    let loginSessionRepository: any LoginSessionRepository

}
