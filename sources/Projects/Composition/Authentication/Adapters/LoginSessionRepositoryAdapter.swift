import DataAuthentication
import DomainAuthentication
import Foundation
import InfrastructureAuthentication
import InfrastructureStorage

// MARK: - LoginSessionRepositoryAdapter

struct LoginSessionRepositoryAdapter: LoginSessionRepository {

    // MARK: Lifecycle

    init(
        remote: HTTPAuthenticationRemote,
        keychainStore: KeychainStore,
        sharedSessionStateMarkerCoding: SharedSessionStateMarkerCoding? = AppGroupUserDefaults.makeShared()
            .map(SharedSessionStateMarkerCoding.init(userDefaults:)),
    ) {
        self.remote = remote
        self.sharedSessionStateMarkerCoding = sharedSessionStateMarkerCoding
        sessionCoding = SessionRecordCoding(keychainStore: keychainStore)
        appleIdentityStore = AppleIdentityKeychainStore(keychainStore: keychainStore)
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
        } catch let error as DataAuthenticationError {
            throw domainLoginError(for: error)
        } catch is KeychainStoreError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func restore() async throws -> AuthenticatedUser? {
        do {
            guard try sessionCoding.load() != nil, let userID = try loadAppleUserID() else { return nil }
            return AuthenticatedUser(id: userID, availability: .available, displayName: nil)
        } catch is KeychainStoreError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func signOut() async throws {
        do {
            try sessionCoding.delete()
            await recordSharedSessionState(isSignedIn: false)
        } catch is KeychainStoreError {
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
        } catch is KeychainStoreError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func updateOnboarding(_ onboarding: LocalOnboardingState) async throws {
        do {
            guard let existing = try sessionCoding.load() else { throw LoginSessionError.temporarilyUnavailable }
            try sessionCoding.save(SessionRecord(tokens: existing.tokens, onboarding: onboarding))
        } catch is KeychainStoreError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func refresh() async throws -> SessionTokens {
        throw LoginSessionError.temporarilyUnavailable
    }

    func verifyAccessToken() async throws {
        do {
            try await remote.verifyAccessToken()
        } catch let error as DataAuthenticationError {
            throw domainVerifyError(for: error)
        }
    }

    // MARK: Private

    private let remote: HTTPAuthenticationRemote
    private let sessionCoding: SessionRecordCoding
    private let appleIdentityStore: AppleIdentityKeychainStore
    private let sharedSessionStateMarkerCoding: SharedSessionStateMarkerCoding?

    private func recordSharedSessionState(isSignedIn: Bool) async {
        await sharedSessionStateMarkerCoding?.save(isSignedIn: isSignedIn)
    }

    private func loadAppleUserID() throws -> String? {
        try appleIdentityStore.load()
    }

    private func domainLoginError(for error: DataAuthenticationError) -> LoginSessionError {
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

    private func domainVerifyError(for error: DataAuthenticationError) -> LoginSessionError {
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
