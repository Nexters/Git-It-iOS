import DataAuthentication
import DomainAuthentication
import Foundation
import InfrastructureAuthentication
import InfrastructureNetworkClient

// MARK: - AuthenticationAssembly

public struct AuthenticationAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
    ) {
        let client = HTTPClient(
            baseURL: baseURL,
            bodyCoding: StandardJSONBodyCoding(),
            responseTimeout: responseTimeout,
        )
        let keychainStore = KeychainStore()
        let authenticationRemote = HTTPAuthenticationRemote(
            client: client,
            accessTokenProvider: {
                guard
                    let data = try? keychainStore.load(
                        for: SessionKeychainLayout.Key.accessToken.rawValue,
                        in: SessionKeychainLayout.namespace,
                    )
                else { return nil }
                return String(data: data, encoding: .utf8)
            },
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
    }

    // MARK: Public

    public let signIn: any SignInUseCase
    public let signOut: any SignOutUseCase
    public let restoreSession: any RestoreSessionUseCase
    public let observeAuthenticationOutcomes: any ObserveAuthenticationOutcomesUseCase

}
