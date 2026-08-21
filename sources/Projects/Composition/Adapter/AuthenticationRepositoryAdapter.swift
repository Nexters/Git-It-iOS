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
        self.keychainStore = keychainStore
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

    func authorizationChanges() async -> AsyncStream<AuthorizationStatus> {
        let changes = await credentialStateProvider.changes()
        return AsyncStream { continuation in
            let task = Task {
                for await state in changes {
                    guard !Task.isCancelled else { break }
                    continuation.yield(domainStatus(state))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func clearAuthentication() async throws {
        do {
            try keychainStore.delete(for: Key.appleUserID.rawValue, in: namespace)
        } catch is KeychainStoreError {
            throw AuthenticationError.temporarilyUnavailable
        }
    }

    // MARK: Private

    private typealias Key = AppleIdentityKeychainLayout.Key

    private let authorizationProvider: AppleAuthorizationProvider
    private let credentialStateProvider: AppleCredentialStateProvider
    private let keychainStore: KeychainStore
    private let namespace = AppleIdentityKeychainLayout.namespace

    private func persistUserID(_ userID: String) throws {
        try keychainStore.save(Data(userID.utf8), for: Key.appleUserID.rawValue, in: namespace)
    }

    private func loadUserID() throws -> String? {
        guard let data = try keychainStore.load(for: Key.appleUserID.rawValue, in: namespace) else { return nil }
        return String(data: data, encoding: .utf8)
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
