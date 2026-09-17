import DataAuthentication
import DataShared
import DomainAuthentication
import Foundation

// MARK: - LoginSessionRepositoryAdapter

struct LoginSessionRepositoryAdapter: LoginSessionRepository {

    // MARK: Lifecycle

    init(
        remote: AuthenticationRemote,
        sessionStorage: any SecureValueStorage,
        appleIdentityStorage: any SecureValueStorage,
        sharedSessionStateMarkerCoding: SharedSessionStateMarkerCoding? = SharedSessionStateMarkerCoding(
            storage: StorageFactory.keyValueStorage(namespace: SessionStorageLayout.sharedSessionNamespace, location: .appGroup)
        ),
    ) {
        self.remote = remote
        self.sharedSessionStateMarkerCoding = sharedSessionStateMarkerCoding
        sessionCoding = SessionRecordCoding(secureStorage: sessionStorage)
        appleIdentityStore = AppleIdentityStore(storage: appleIdentityStorage)
    }

    // MARK: Internal

    func start(with grant: AuthenticationGrant) async throws -> AuthenticatedUser {
        do {
            let response = try await remote.appleLogin(idToken: grant.id.rawValue)
            try sessionCoding.save(SessionRecord(
                tokens: SessionTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken,
                    accessTokenExpiresAt: nil,
                    refreshTokenExpiresAt: nil,
                ),
                onboarding: LocalOnboardingState(
                    needsCuration: response.needsCuration,
                    acceptedLegalVersions: [],
                    acceptedAt: nil,
                ),
            ))
            await recordSharedSessionState(isSignedIn: true)
            guard let userID = try loadAppleUserID() else { throw LoginSessionError.temporarilyUnavailable }
            return AuthenticatedUser(id: userID, availability: .available, displayName: nil)
        } catch let error as AuthenticationServiceError {
            throw domainLoginError(for: error)
        } catch is SecureValueStorageError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func restore() async throws -> AuthenticatedUser? {
        do {
            guard try sessionCoding.load() != nil, let userID = try loadAppleUserID() else { return nil }
            return AuthenticatedUser(id: userID, availability: .available, displayName: nil)
        } catch is SecureValueStorageError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func signOut() async throws {
        do {
            try sessionCoding.delete()
            await recordSharedSessionState(isSignedIn: false)
        } catch is SecureValueStorageError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func currentSession() async -> SessionRecord? {
        try? sessionCoding.load()
    }

    func replaceTokens(_ tokens: SessionTokens) async throws {
        do {
            let onboarding = try sessionCoding.load()?.onboarding
                ?? LocalOnboardingState(needsCuration: false, acceptedLegalVersions: [], acceptedAt: nil)
            try sessionCoding.save(SessionRecord(tokens: tokens, onboarding: onboarding))
        } catch is SecureValueStorageError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func updateOnboarding(_ onboarding: LocalOnboardingState) async throws {
        do {
            guard let existing = try sessionCoding.load() else { throw LoginSessionError.temporarilyUnavailable }
            try sessionCoding.save(SessionRecord(tokens: existing.tokens, onboarding: onboarding))
        } catch is SecureValueStorageError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func refresh() async throws -> SessionTokens {
        throw LoginSessionError.temporarilyUnavailable
    }

    func verifyAccessToken() async throws {
        do {
            try await remote.verifyAccessToken()
        } catch let error as AuthenticationServiceError {
            throw domainVerifyError(for: error)
        }
    }

    // MARK: Private

    private let remote: AuthenticationRemote
    private let sessionCoding: SessionRecordCoding
    private let appleIdentityStore: AppleIdentityStore
    private let sharedSessionStateMarkerCoding: SharedSessionStateMarkerCoding?

    private func recordSharedSessionState(isSignedIn: Bool) async {
        await sharedSessionStateMarkerCoding?.save(isSignedIn: isSignedIn)
    }

    private func loadAppleUserID() throws -> String? {
        try appleIdentityStore.load()
    }

    private func domainLoginError(for error: AuthenticationServiceError) -> LoginSessionError {
        switch error {
        case .unauthorized:
            .refreshRejectedOrExpired

        case .invalidRequest:
            .accountUnavailable

        case .temporarilyUnavailable,
             .transport,
             .unexpectedStatus:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

    private func domainVerifyError(for error: AuthenticationServiceError) -> LoginSessionError {
        switch error {
        case .unauthorized:
            .unauthorized

        case .invalidRequest,
             .temporarilyUnavailable,
             .transport,
             .unexpectedStatus:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

}
