import DataAuthentication
import DataLegalConsent
import DomainAuthentication
import Foundation
import InfrastructureAuthentication
import InfrastructureCache
import InfrastructureNetworkClient

// MARK: - AuthenticationAssembly

public struct AuthenticationAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        policyDocuments: [PolicyDocument] = [],
        keychainStore: KeychainStore = KeychainStore(),
        policyConsentStore: any PolicyConsentStore = LocalPolicyConsentStore(
            store: UserDefaultsStore(namespace: "com.nexters.hytime.gitit.legalConsent")
        ),
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
        // `signOut`은 멤버 404 뒤 명시적 local cleanup에도 그대로 재사용된다(신규 UseCase를
        // 따로 두지 않음, spec.md 외부 의존성 "기존 SignOutUseCase와 로컬 인증 세션 정리 계약").
        policyConsent = PolicyConsentRepositoryAdapter(
            manifestDocuments: policyDocuments,
            store: policyConsentStore,
        )
        self.loginSessionRepository = loginSessionRepository
    }

    // MARK: Public

    public let signIn: any SignInUseCase
    public let signOut: any SignOutUseCase
    public let restoreSession: any RestoreSessionUseCase
    public let observeAuthenticationOutcomes: any ObserveAuthenticationOutcomesUseCase
    public let refreshSession: any RefreshSessionUseCase
    public let verifyAccessToken: any VerifyAccessTokenUseCase
    public let policyConsent: any PolicyConsentUseCase

    // MARK: Internal

    /// `AppComposition`이 다른 조립체(예: `MemberAssembly`의 curation 조정)와 세션 상태를
    /// 공유하기 위해 사용하는 non-public 참조입니다. public API 표면(any XxxUseCase)에는
    /// 포함되지 않습니다.
    let loginSessionRepository: any LoginSessionRepository

}
