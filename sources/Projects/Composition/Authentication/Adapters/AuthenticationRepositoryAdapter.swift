import DataAuthentication
import DomainAuthentication
import Foundation
import InfrastructureAuthentication

// MARK: - AuthenticationRepositoryAdapter

actor AuthenticationRepositoryAdapter: AuthenticationRepository {

    // MARK: Lifecycle

    init(
        authorizationProvider: AppleAuthorizationProvider,
        credentialStateProvider: AppleCredentialStateProvider,
        keychainStore: KeychainStore,
    ) {
        self.authorizationProvider = authorizationProvider
        self.credentialStateProvider = credentialStateProvider
        appleIdentityStore = AppleIdentityKeychainStore(keychainStore: keychainStore)
    }

    // MARK: Internal

    func authenticate(using method: AuthenticationMethod) async throws -> AuthenticationGrant {
        switch method {
        case .apple:
            do {
                let credential = try await authorizationProvider.authorize()
                guard
                    let tokenData = credential.identityToken,
                    let idToken = String(data: tokenData, encoding: .utf8)
                else {
                    throw AuthenticationError.temporarilyUnavailable
                }
                try? persistUserID(credential.userID)
                return AuthenticationGrant(id: .init(rawValue: idToken), method: .apple)
            } catch let error as AppleAuthorizationError {
                throw domainError(for: error)
            }

        @unknown default:
            throw AuthenticationError.temporarilyUnavailable
        }
    }

    func authorizationStatus() async throws -> AuthorizationStatus {
        guard let userID = try? loadUserID() else { return .reauthenticationRequired }
        return domainStatus(await credentialStateProvider.state(for: userID))
    }

    func clearAuthentication() async throws {
        do {
            try appleIdentityStore.delete()
        } catch is KeychainStoreError {
            throw AuthenticationError.temporarilyUnavailable
        }
    }

    // MARK: Private

    private let authorizationProvider: AppleAuthorizationProvider
    private let credentialStateProvider: AppleCredentialStateProvider
    private let appleIdentityStore: AppleIdentityKeychainStore

    private func persistUserID(_ userID: String) throws {
        try appleIdentityStore.save(userID)
    }

    private func loadUserID() throws -> String? {
        try appleIdentityStore.load()
    }

    private func domainStatus(_ state: AppleCredentialState) -> AuthorizationStatus {
        switch state {
        case .authorized:
            .authorized

        case .revoked,
             .notFound,
             .transferred:
            .reauthenticationRequired

        case .temporarilyUnavailable:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

    private func domainError(for error: AppleAuthorizationError) -> AuthenticationError {
        switch error {
        case .cancelled:
            .cancelled

        case .invalidCallback,
             .expiredAttempt,
             .missingCredential,
             .unavailable:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

}
