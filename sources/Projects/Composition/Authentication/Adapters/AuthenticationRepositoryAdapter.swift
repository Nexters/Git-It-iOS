import DataAuthentication
import DataShared
import DomainAuthentication
import Foundation

// MARK: - AuthenticationRepositoryAdapter

actor AuthenticationRepositoryAdapter: AuthenticationRepository {

    // MARK: Lifecycle

    init(
        appleSignInSource: AppleSignInSource,
        secureStorage: any SecureValueStorage,
    ) {
        self.appleSignInSource = appleSignInSource
        appleIdentityStore = AppleIdentityStore(storage: secureStorage)
    }

    // MARK: Internal

    func authenticate(using method: AuthenticationMethod) async throws -> AuthenticationGrant {
        switch method {
        case .apple:
            do {
                let credential = try await appleSignInSource.authorize()
                try? persistUserID(credential.userID)
                return AuthenticationGrant(id: .init(rawValue: credential.identityToken), method: .apple)
            } catch let error as AppleSignInError {
                throw domainError(for: error)
            }

        @unknown default:
            throw AuthenticationError.temporarilyUnavailable
        }
    }

    func authorizationStatus() async throws -> AuthorizationStatus {
        guard let userID = try? loadUserID() else { return .reauthenticationRequired }
        return domainStatus(await appleSignInSource.state(forUserID: userID))
    }

    func clearAuthentication() async throws {
        do {
            try appleIdentityStore.delete()
        } catch is SecureValueStorageError {
            throw AuthenticationError.temporarilyUnavailable
        }
    }

    // MARK: Private

    private let appleSignInSource: AppleSignInSource
    private let appleIdentityStore: AppleIdentityStore

    private func persistUserID(_ userID: String) throws {
        try appleIdentityStore.save(userID)
    }

    private func loadUserID() throws -> String? {
        try appleIdentityStore.load()
    }

    private func domainStatus(_ state: AppleSignInState) -> AuthorizationStatus {
        switch state {
        case .authorized:
            .authorized

        case .reauthenticationRequired:
            .reauthenticationRequired

        case .temporarilyUnavailable:
            .temporarilyUnavailable
        }
    }

    private func domainError(for error: AppleSignInError) -> AuthenticationError {
        switch error {
        case .cancelled:
            .cancelled

        case .unavailable:
            .temporarilyUnavailable
        }
    }

}
