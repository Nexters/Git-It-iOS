import Foundation
import Testing
@testable import DataAuthentication
@testable import InfrastructureAuthentication

// MARK: - SessionKeychainMigrationTests

@Suite("SessionKeychainMigration")
struct SessionKeychainMigrationTests {

    // MARK: Internal

    @Test
    func `접근 그룹이 없던 기존 세션을 공유 저장소로 옮기고 기존 항목을 지운다`() throws {
        let backend = KeychainStore.InMemoryBackend()
        let shared = KeychainStore(
            backend: backend,
            accessGroup: AppGroupKeychainStore.accessGroup,
        )
        let legacy = KeychainStore(backend: backend)
        try SessionRecordKeychainCoding(keychainStore: legacy).save(Self.record(accessToken: "legacy-token"))

        let outcome = SessionKeychainMigration(
            sharedKeychainStore: shared,
            legacyKeychainStore: legacy,
        )()

        #expect(outcome == .migrated)
        #expect(try SessionRecordKeychainCoding(keychainStore: shared).load()?.accessToken == "legacy-token")
        #expect(try SessionRecordKeychainCoding(keychainStore: legacy).load() == nil)
    }

    @Test
    func `공유 저장소에 이미 세션이 있으면 아무것도 바꾸지 않는다`() throws {
        let backend = KeychainStore.InMemoryBackend()
        let shared = KeychainStore(
            backend: backend,
            accessGroup: AppGroupKeychainStore.accessGroup,
        )
        let legacy = KeychainStore(backend: backend)
        try SessionRecordKeychainCoding(keychainStore: shared).save(Self.record(accessToken: "shared-token"))
        try SessionRecordKeychainCoding(keychainStore: legacy).save(Self.record(accessToken: "legacy-token"))

        let outcome = SessionKeychainMigration(
            sharedKeychainStore: shared,
            legacyKeychainStore: legacy,
        )()

        #expect(outcome == .alreadyMigrated)
        #expect(try SessionRecordKeychainCoding(keychainStore: shared).load()?.accessToken == "shared-token")
        #expect(try SessionRecordKeychainCoding(keychainStore: legacy).load()?.accessToken == "legacy-token")
    }

    @Test
    func `옮길 세션이 없으면 어느 저장소에도 쓰지 않는다`() throws {
        let backend = KeychainStore.InMemoryBackend()
        let shared = KeychainStore(
            backend: backend,
            accessGroup: AppGroupKeychainStore.accessGroup,
        )
        let legacy = KeychainStore(backend: backend)

        let outcome = SessionKeychainMigration(
            sharedKeychainStore: shared,
            legacyKeychainStore: legacy,
        )()

        #expect(outcome == .nothingToMigrate)
        #expect(try SessionRecordKeychainCoding(keychainStore: shared).load() == nil)
        #expect(try SessionRecordKeychainCoding(keychainStore: legacy).load() == nil)
    }

    // MARK: Private

    private static func record(accessToken: String) -> StoredSessionRecord {
        StoredSessionRecord(
            accessToken: accessToken,
            refreshToken: "refresh",
            accessTokenExpiresAt: nil,
            refreshTokenExpiresAt: nil,
            needsCuration: false,
            acceptedLegalVersions: [],
            acceptedAt: nil,
        )
    }

}
