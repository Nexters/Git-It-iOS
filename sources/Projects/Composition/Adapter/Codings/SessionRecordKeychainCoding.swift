import DomainAuthentication
import Foundation
import InfrastructureAuthentication

struct SessionRecordKeychainCoding: Sendable {

    // MARK: Lifecycle

    init(keychainStore: KeychainStore) {
        self.keychainStore = keychainStore
    }

    // MARK: Internal

    func load() throws -> SessionRecord? {
        guard let data = try keychainStore.load(for: key, in: namespace) else { return nil }
        let wire = try JSONDecoder().decode(Wire.self, from: data)
        return wire.record
    }

    func save(_ record: SessionRecord) throws {
        let data = try JSONEncoder().encode(Wire(record: record))
        try keychainStore.save(data, for: key, in: namespace)
    }

    func delete() throws {
        try keychainStore.delete(for: key, in: namespace)
    }

    // MARK: Private

    private struct Wire: Codable {

        // MARK: Lifecycle

        init(record: SessionRecord) {
            accessToken = record.tokens.accessToken
            refreshToken = record.tokens.refreshToken
            accessTokenExpiresAt = record.tokens.accessTokenExpiresAt
            refreshTokenExpiresAt = record.tokens.refreshTokenExpiresAt
            needsCuration = record.onboarding.needsCuration
            acceptedLegalVersions = record.onboarding.acceptedLegalVersions
            acceptedAt = record.onboarding.acceptedAt
        }

        // MARK: Internal

        let accessToken: String
        let refreshToken: String
        let accessTokenExpiresAt: Date?
        let refreshTokenExpiresAt: Date?
        let needsCuration: Bool
        let acceptedLegalVersions: [String]
        let acceptedAt: Date?

        var record: SessionRecord {
            SessionRecord(
                tokens: SessionTokens(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    accessTokenExpiresAt: accessTokenExpiresAt,
                    refreshTokenExpiresAt: refreshTokenExpiresAt,
                ),
                onboarding: LocalOnboardingState(
                    needsCuration: needsCuration,
                    acceptedLegalVersions: acceptedLegalVersions,
                    acceptedAt: acceptedAt,
                ),
            )
        }

    }

    private let keychainStore: KeychainStore
    private let key = SessionKeychainLayout.Key.sessionRecord.rawValue
    private let namespace = SessionKeychainLayout.namespace

}
