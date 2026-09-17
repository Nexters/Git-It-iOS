import CompositionShared
import DataAuthentication
import DataLegalConsent
import DataShared
import DomainAuthentication
import Foundation
import InfrastructureAuthentication
import InfrastructureNetworkClient

// MARK: - AuthenticationAssembly

public struct AuthenticationAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        policyDocuments: [PolicyDocument] = [],
        keychainStore: KeychainStore = KeychainStore(),
        policyConsentStore: LocalPolicyConsentStore = LocalPolicyConsentStore(
            storage: StorageFactory.keyValueStorage(namespace: PolicyConsentStorageLayout.namespace, location: .device)
        ),
        sharedStorage: (any KeyValueStorage)? = StorageFactory.keyValueStorage(
            namespace: SessionStorageLayout.sharedSessionNamespace,
            location: .appGroup,
        ),
        transport: (any HTTPTransport)? = nil,
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
    ) {
        let accessTokenProvider: @Sendable () async -> String? = {
            (try? SessionRecordCoding(keychainStore: keychainStore).load())?.tokens.accessToken
        }
        let client = makeHTTPClient(baseURL: baseURL, responseTimeout: responseTimeout, transport: transport)
        let authenticationRemote = AuthenticationRemote(
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
        verifyAuthorization = VerifyAuthorization(
            authenticationRepository: authenticationRepository,
            loginSessionRepository: loginSessionRepository,
        )
        refreshSession = RefreshSession(loginSessionRepository: loginSessionRepository)
        policyConsent = PolicyConsent(
            manifestDocuments: policyDocuments,
            policyConsentRepository: PolicyConsentRepositoryAdapter(store: policyConsentStore),
        )
        self.loginSessionRepository = loginSessionRepository
        self.accessTokenProvider = accessTokenProvider

        let markerCoding = sharedStorage.map(SharedSessionStateMarkerCoding.init(storage:))
        recordSharedSessionState = {
            await markerCoding?.save(isSignedIn: accessTokenProvider() != nil)
        }
    }

    // MARK: Public

    public let signIn: any SignInUseCase
    public let signOut: any SignOutUseCase
    public let restoreSession: any RestoreSessionUseCase
    public let verifyAuthorization: any VerifyAuthorizationUseCase
    public let refreshSession: any RefreshSessionUseCase
    public let policyConsent: any PolicyConsentUseCase

    public let accessTokenProvider: @Sendable () async -> String?

    public let loginSessionRepository: any LoginSessionRepository

    public let recordSharedSessionState: @Sendable () async -> Void

}
