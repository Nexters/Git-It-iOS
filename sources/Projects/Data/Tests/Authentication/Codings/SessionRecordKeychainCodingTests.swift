import Foundation
import Testing
@testable import DataAuthentication
@testable import InfrastructureAuthentication

// MARK: - SessionRecordKeychainCodingTests

@Suite("SessionRecordKeychainCoding")
struct SessionRecordKeychainCodingTests {

    // MARK: Internal

    @Test
    func `저장한 세션을 같은 값으로 다시 읽는다`() throws {
        let store = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let coding = SessionRecordKeychainCoding(keychainStore: store)

        try coding.save(Self.record)

        #expect(try coding.load() == Self.record)
    }

    @Test
    func `세션은 기존 네임스페이스와 키 자리에 저장된다`() throws {
        let store = KeychainStore(backend: KeychainStore.InMemoryBackend())

        try SessionRecordKeychainCoding(keychainStore: store).save(Self.record)

        let stored = try store.load(
            for: "sessionRecord",
            in: KeychainNamespace("com.nexters.hytime.gitit.session"),
        )
        #expect(stored != nil)
    }

    @Test
    func `저장 형식은 기존 필드 이름을 그대로 쓴다`() throws {
        let store = KeychainStore(backend: KeychainStore.InMemoryBackend())
        try SessionRecordKeychainCoding(keychainStore: store).save(Self.record)
        let stored = try #require(try store.load(
            for: "sessionRecord",
            in: KeychainNamespace("com.nexters.hytime.gitit.session"),
        ))

        let json = try #require(JSONSerialization.jsonObject(with: stored) as? [String: Any])

        #expect(json["accessToken"] as? String == "access")
        #expect(json["refreshToken"] as? String == "refresh")
        #expect(json["needsCuration"] as? Bool == true)
        #expect(json["acceptedLegalVersions"] as? [String] == ["v1"])
    }

    @Test
    func `삭제한 뒤에는 세션을 읽을 수 없다`() throws {
        let store = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let coding = SessionRecordKeychainCoding(keychainStore: store)
        try coding.save(Self.record)

        try coding.delete()

        #expect(try coding.load() == nil)
    }

    // MARK: Private

    private static let record = StoredSessionRecord(
        accessToken: "access",
        refreshToken: "refresh",
        accessTokenExpiresAt: nil,
        refreshTokenExpiresAt: nil,
        needsCuration: true,
        acceptedLegalVersions: ["v1"],
        acceptedAt: nil,
    )

}
