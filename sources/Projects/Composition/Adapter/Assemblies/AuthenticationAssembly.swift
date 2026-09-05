import DataAuthentication
import DataLegalConsent
import DomainAuthentication
import Foundation
import InfrastructureAuthentication
import InfrastructureNetworkClient
import InfrastructureStorage

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
        authenticationOutcomes = AuthenticationOutcomes(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )
        refreshSession = RefreshSession(loginSessionRepository: loginSessionRepository)
        verifyAccessToken = VerifyAccessToken(loginSessionRepository: loginSessionRepository)
        policyConsent = PolicyConsent(
            manifestDocuments: policyDocuments,
            policyConsentRepository: PolicyConsentRepositoryAdapter(store: policyConsentStore),
        )
        self.loginSessionRepository = loginSessionRepository
        self.accessTokenProvider = accessTokenProvider
    }

    // MARK: Public

    public let signIn: any SignInUseCase
    public let signOut: any SignOutUseCase
    public let restoreSession: any RestoreSessionUseCase
    public let authenticationOutcomes: any AuthenticationOutcomesUseCase
    public let refreshSession: any RefreshSessionUseCase
    public let verifyAccessToken: any VerifyAccessTokenUseCase
    public let policyConsent: any PolicyConsentUseCase

    /// 저장된 세션의 접근 토큰을 그대로 돌려준다. 갱신을 수행하지 않는다.
    public let accessTokenProvider: @Sendable () async -> String?

    public let loginSessionRepository: any LoginSessionRepository

}
