import Foundation
import InfrastructureAuthentication

// MARK: - AppleSignInSource

public actor AppleSignInSource {

    // MARK: Lifecycle

    public init() {
        let authorizationProvider = AppleAuthorizationProvider()
        let credentialStateProvider = AppleCredentialStateProvider()
        self.init(
            authorize: { try await authorizationProvider.authorize() },
            credentialState: { userID in await credentialStateProvider.state(for: userID) },
        )
    }

    init(
        authorize: @escaping @Sendable () async throws -> AppleCredential,
        credentialState: @escaping @Sendable (String) async -> AppleCredentialState,
    ) {
        authorizeCredential = authorize
        self.credentialState = credentialState
    }

    // MARK: Public

    public func authorize() async throws(AppleSignInError) -> AppleSignInCredential {
        let credential: AppleCredential
        do {
            credential = try await authorizeCredential()
        } catch AppleAuthorizationError.cancelled {
            throw AppleSignInError.cancelled
        } catch {
            throw AppleSignInError.unavailable
        }
        guard
            let tokenData = credential.identityToken,
            let identityToken = String(
                data: tokenData,
                encoding: .utf8,
            )
        else {
            throw AppleSignInError.unavailable
        }
        return AppleSignInCredential(
            userID: credential.userID,
            identityToken: identityToken,
        )
    }

    public func state(forUserID userID: String) async -> AppleSignInState {
        switch await credentialState(userID) {
        case .authorized:
            .authorized

        case .revoked,
             .notFound,
             .transferred:
            .reauthenticationRequired

        case .temporarilyUnavailable:
            .temporarilyUnavailable
        }
    }

    // MARK: Private

    private let authorizeCredential: @Sendable () async throws -> AppleCredential
    private let credentialState: @Sendable (String) async -> AppleCredentialState

}
