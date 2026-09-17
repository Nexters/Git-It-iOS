import DataShared
import Foundation
import Testing

@testable import DataAuthentication

@Suite("RequestCredentialProvider")
struct RequestCredentialProviderTests {

    // MARK: Internal

    @Test
    func `저장된 로그인 기록이 없으면 로그아웃 상태를 알린다`() async {
        let storage = InMemorySecureValueStorage()
        let provider = RequestCredentialProvider(secureStorage: storage, now: { Self.now })

        #expect(await provider.credential() == .signedOut)
    }

    @Test
    func `저장 기록을 읽지 못하면 로그아웃 상태를 알린다`() async {
        let storage = InMemorySecureValueStorage()
        try Self.store(Self.record(expiresAt: Self.now.addingTimeInterval(60)), in: storage)
        storage.fail(with: .unavailable)
        let provider = RequestCredentialProvider(secureStorage: storage, now: { Self.now })

        #expect(await provider.credential() == .signedOut)
    }

    @Test
    func `유효한 기록이 있으면 access token을 전달한다`() async throws {
        let storage = InMemorySecureValueStorage()
        try Self.store(Self.record(expiresAt: Self.now.addingTimeInterval(60)), in: storage)
        let provider = RequestCredentialProvider(secureStorage: storage, now: { Self.now })

        #expect(await provider.credential() == .available("access-token"))
    }

    @Test
    func `만료된 기록은 삭제하고 무효 신호를 한 번 보낸다`() async throws {
        let storage = InMemorySecureValueStorage()
        try Self.store(Self.record(expiresAt: Self.now), in: storage)
        let provider = RequestCredentialProvider(secureStorage: storage, now: { Self.now })
        var invalidations = provider.invalidations().makeAsyncIterator()

        #expect(await provider.credential() == .signedOut)

        let invalidation = await invalidations.next()
        #expect(invalidation != nil)
        #expect(storage.storedData(forKey: Self.key) == nil)
        #expect(await provider.credential() == .signedOut)
    }

    @Test
    func `요청이 거부되면 기록을 삭제하고 무효 신호를 보낸다`() async throws {
        let storage = InMemorySecureValueStorage()
        try Self.store(Self.record(expiresAt: Self.now.addingTimeInterval(60)), in: storage)
        let provider = RequestCredentialProvider(secureStorage: storage, now: { Self.now })
        var invalidations = provider.invalidations().makeAsyncIterator()

        await provider.credentialRejected()

        let invalidation = await invalidations.next()
        #expect(invalidation != nil)
        #expect(storage.storedData(forKey: Self.key) == nil)
    }

    @Test
    func `저장 기록이 없으면 거부를 받아도 무효 신호를 보내지 않는다`() async throws {
        let storage = InMemorySecureValueStorage()
        let provider = RequestCredentialProvider(secureStorage: storage, now: { Self.now })
        var invalidations = provider.invalidations().makeAsyncIterator()

        await provider.credentialRejected()
        try Self.store(Self.record(expiresAt: Self.now.addingTimeInterval(60)), in: storage)
        await provider.credentialRejected()

        let invalidation = await invalidations.next()
        #expect(invalidation != nil)
        #expect(storage.storedData(forKey: Self.key) == nil)
    }

    @Test
    func `구독자 둘이 모두 무효 신호를 받는다`() async throws {
        let storage = InMemorySecureValueStorage()
        try Self.store(Self.record(expiresAt: Self.now.addingTimeInterval(60)), in: storage)
        let provider = RequestCredentialProvider(secureStorage: storage, now: { Self.now })
        var first = provider.invalidations().makeAsyncIterator()
        var second = provider.invalidations().makeAsyncIterator()

        await provider.credentialRejected()

        let firstInvalidation = await first.next()
        let secondInvalidation = await second.next()
        #expect(firstInvalidation != nil)
        #expect(secondInvalidation != nil)
    }

    // MARK: Private

    private static let now = Date(timeIntervalSince1970: 1_000)
    private static let key = SessionStorageLayout.Key.sessionRecord.rawValue

    private static func record(expiresAt: Date?) -> StoredSessionRecord {
        StoredSessionRecord(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            accessTokenExpiresAt: expiresAt,
            refreshTokenExpiresAt: nil,
            needsCuration: false,
            acceptedLegalVersions: [],
            acceptedAt: nil,
        )
    }

    private static func store(
        _ record: StoredSessionRecord,
        in storage: InMemorySecureValueStorage,
    ) throws {
        try SessionRecordStorageCoding(storage: storage).save(record)
    }

}
