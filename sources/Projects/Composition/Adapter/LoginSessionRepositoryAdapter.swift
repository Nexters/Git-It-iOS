import DataAuthentication
import DomainAuthentication
import Foundation
import InfrastructureAuthentication

// MARK: - LoginSessionRepositoryAdapter

struct LoginSessionRepositoryAdapter: LoginSessionRepository {

    // MARK: Lifecycle

    init(
        remote: AuthenticationRemote,
        keychainStore: KeychainStore,
    ) {
        self.remote = remote
        self.keychainStore = keychainStore
        sessionCoding = SessionRecordKeychainCoding(keychainStore: keychainStore)
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
            // 사용자 ID는 idToken(JWT, 로그인마다 값이 바뀔 수 있음)이 아니라
            // `AuthenticationRepositoryAdapter`가 저장한 Apple 안정 식별자를 사용한다(GAP-014-007).
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
        // UC12: 서버 refresh endpoint 미확보(INT-API-001). 임의 성공을 만들지 않고 capability
        // 부재를 그대로 던진다.
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

    private typealias AppleIdentityKey = AppleIdentityKeychainLayout.Key

    private let remote: AuthenticationRemote
    private let keychainStore: KeychainStore
    private let sessionCoding: SessionRecordKeychainCoding

    private func loadAppleUserID() throws -> String? {
        guard
            let data = try keychainStore.load(
                for: AppleIdentityKey.appleUserID.rawValue,
                in: AppleIdentityKeychainLayout.namespace,
            )
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func domainLoginError(for error: DataAuthenticationError) -> LoginSessionError {
        switch error {
        case .unauthorized:
            .refreshRejectedOrExpired

        case .invalidRequest:
            .accountUnavailable

        case .temporarilyUnavailable,
             .transport,
             .decoding,
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
             .decoding,
             .unexpectedStatus:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

}
