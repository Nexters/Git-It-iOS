import DataAuthentication
import DomainAuthentication
import Foundation
import InfrastructureAuthentication

// MARK: - SessionRecordCoding

struct SessionRecordCoding: Sendable {

    // MARK: Lifecycle

    init(keychainStore: KeychainStore) {
        coding = SessionRecordKeychainCoding(keychainStore: keychainStore)
    }

    // MARK: Internal

    func load() throws -> SessionRecord? {
        guard let stored = try coding.load() else { return nil }
        return SessionRecord(
            tokens: SessionTokens(
                accessToken: stored.accessToken,
                refreshToken: stored.refreshToken,
                accessTokenExpiresAt: stored.accessTokenExpiresAt,
                refreshTokenExpiresAt: stored.refreshTokenExpiresAt,
            ),
            onboarding: LocalOnboardingState(
                needsCuration: stored.needsCuration,
                acceptedLegalVersions: stored.acceptedLegalVersions,
                acceptedAt: stored.acceptedAt,
            ),
        )
    }

    func save(_ record: SessionRecord) throws {
        try coding.save(StoredSessionRecord(
            accessToken: record.tokens.accessToken,
            refreshToken: record.tokens.refreshToken,
            accessTokenExpiresAt: record.tokens.accessTokenExpiresAt,
            refreshTokenExpiresAt: record.tokens.refreshTokenExpiresAt,
            needsCuration: record.onboarding.needsCuration,
            acceptedLegalVersions: record.onboarding.acceptedLegalVersions,
            acceptedAt: record.onboarding.acceptedAt,
        ))
    }

    func delete() throws {
        try coding.delete()
    }

    // MARK: Private

    private let coding: SessionRecordKeychainCoding

}
