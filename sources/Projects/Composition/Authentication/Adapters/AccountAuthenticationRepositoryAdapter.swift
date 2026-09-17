import DataAuthentication
import DataShared
import DomainAccount
import Foundation

// MARK: - AccountAuthenticationRepositoryAdapter

public actor AccountAuthenticationRepositoryAdapter: DomainAccount.AuthenticationRepository {

    // MARK: Lifecycle

    public init(
        appleSignInSource: AppleSignInSource,
        secureStorage: any SecureValueStorage,
    ) {
        self.appleSignInSource = appleSignInSource
        appleIdentityStore = AppleIdentityStore(storage: secureStorage)
    }

    // MARK: Public

    public func authenticate(using method: SignInMethod) async throws -> AuthenticationGrant {
        switch method {
        case .apple:
            do {
                let credential = try await appleSignInSource.authorize()
                try? appleIdentityStore.save(credential.userID)
                return AuthenticationGrant(id: credential.identityToken, method: .apple)
            } catch let error as AppleSignInError {
                throw domainError(for: error)
            }

        @unknown default:
            throw AccountError.temporarilyUnavailable
        }
    }

    public func authorizationStatus() async throws -> SignInVerification {
        guard let userID = try? appleIdentityStore.load() else { return .reauthenticationRequired }
        return verification(for: await appleSignInSource.state(forUserID: userID))
    }

    public func clearAuthentication() async throws {
        do {
            try appleIdentityStore.delete()
        } catch is SecureValueStorageError {
            throw AccountError.temporarilyUnavailable
        }
    }

    // MARK: Private

    private let appleSignInSource: AppleSignInSource
    private let appleIdentityStore: AppleIdentityStore

    private func verification(for state: AppleSignInState) -> SignInVerification {
        switch state {
        case .authorized:
            .valid

        case .reauthenticationRequired:
            .reauthenticationRequired

        case .temporarilyUnavailable:
            .temporarilyUnavailable
        }
    }

    private func domainError(for error: AppleSignInError) -> AccountError {
        switch error {
        case .cancelled:
            .signInCancelled

        case .unavailable:
            .temporarilyUnavailable
        }
    }

}
