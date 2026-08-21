import DomainAuthentication
import Foundation
import InfrastructureAuthentication

/// `SessionRecord`를 단일 key 아래 JSON blob으로 원자적으로 저장·조회한다. token pair와
/// onboarding state를 분리된 key로 나누면 하나만 갱신되다 실패하는 부분 상태가 생길 수 있어
/// 이를 막는다(GAP-014-008, GAP-014-009).
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
