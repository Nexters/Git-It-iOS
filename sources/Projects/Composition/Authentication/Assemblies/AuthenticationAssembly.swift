import DataAuthentication
import DataLegalConsent
import DataShared
import DomainAuthentication
import Foundation

// MARK: - AuthenticationAssembly

public struct AuthenticationAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        policyDocuments: [PolicyDocument] = [],
        secureStorage: (any SecureValueStorage)? = nil,
        policyConsentStore: LocalPolicyConsentStore = LocalPolicyConsentStore(
            storage: StorageFactory.keyValueStorage(namespace: PolicyConsentStorageLayout.namespace, location: .device)
        ),
        sharedStorage: (any KeyValueStorage)? = StorageFactory.keyValueStorage(
            namespace: SessionStorageLayout.sharedSessionNamespace,
            location: .appGroup,
        ),
        transport: (any RequestTransport)? = nil,
        responseTimeout: Duration = RequestClientFactory.defaultResponseTimeout,
    ) {
        let sessionStorage = secureStorage ?? StorageFactory.secureValueStorage(
            namespace: SessionStorageLayout.namespace,
            location: .appGroup,
        )
        let appleIdentityStorage = secureStorage ?? StorageFactory.secureValueStorage(
            namespace: AppleIdentityStorageLayout.namespace,
            location: .appGroup,
        )
        let requestCredentialProvider = RequestCredentialProvider(secureStorage: sessionStorage)
        let authenticationRemote = AuthenticationRemote(
            baseURL: baseURL,
            transport: transport,
            responseTimeout: responseTimeout,
            credential: { await requestCredentialProvider.credential() },
        )
        let authenticationRepository = AuthenticationRepositoryAdapter(
            appleSignInSource: AppleSignInSource(),
            secureStorage: appleIdentityStorage,
        )
        let loginSessionRepository = LoginSessionRepositoryAdapter(
            remote: authenticationRemote,
            sessionStorage: sessionStorage,
            appleIdentityStorage: appleIdentityStorage,
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
        self.requestCredentialProvider = requestCredentialProvider

        let markerCoding = sharedStorage.map(SharedSessionStateMarkerCoding.init(storage:))
        recordSharedSessionState = {
            await markerCoding?.save(isSignedIn: requestCredentialProvider.credential() != .signedOut)
        }
    }

    // MARK: Public

    public let signIn: any SignInUseCase
    public let signOut: any SignOutUseCase
    public let restoreSession: any RestoreSessionUseCase
    public let verifyAuthorization: any VerifyAuthorizationUseCase
    public let refreshSession: any RefreshSessionUseCase
    public let policyConsent: any PolicyConsentUseCase

    public let requestCredentialProvider: RequestCredentialProvider

    public let loginSessionRepository: any LoginSessionRepository

    public let recordSharedSessionState: @Sendable () async -> Void

}
