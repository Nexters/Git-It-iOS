import Foundation
import Testing
@testable import DataAuthentication

// MARK: - SessionRecordStorageCodingTests

@Suite("SessionRecordStorageCoding")
struct SessionRecordStorageCodingTests {

    // MARK: Internal

    @Test
    func `저장한 세션을 같은 값으로 다시 읽는다`() throws {
        let coding = SessionRecordStorageCoding(storage: InMemorySecureValueStorage())

        try coding.save(Self.record)

        #expect(try coding.load() == Self.record)
    }

    @Test
    func `세션은 기존 키 자리에 저장된다`() throws {
        let storage = InMemorySecureValueStorage()

        try SessionRecordStorageCoding(storage: storage).save(Self.record)

        #expect(storage.storedData(forKey: "sessionRecord") != nil)
    }

    @Test
    func `저장 형식은 기존 필드 이름을 그대로 쓴다`() throws {
        let storage = InMemorySecureValueStorage()
        try SessionRecordStorageCoding(storage: storage).save(Self.record)
        let stored = try #require(storage.storedData(forKey: "sessionRecord"))

        let json = try #require(JSONSerialization.jsonObject(with: stored) as? [String: Any])

        #expect(json["accessToken"] as? String == "access")
        #expect(json["refreshToken"] as? String == "refresh")
        #expect(json["needsCuration"] as? Bool == true)
        #expect(json["acceptedLegalVersions"] as? [String] == ["v1"])
    }

    @Test
    func `삭제한 뒤에는 세션을 읽을 수 없다`() throws {
        let coding = SessionRecordStorageCoding(storage: InMemorySecureValueStorage())
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
