import Foundation
import Testing

@testable import DataAuthentication

// MARK: - SharedSessionStateMarkerCodingTests

@Suite("SharedSessionStateMarkerCoding")
struct SharedSessionStateMarkerCodingTests {

    // MARK: Internal

    @Test
    func `저장한 로그인 상태를 다시 조회한다`() async {
        let coding = SharedSessionStateMarkerCoding(storage: InMemoryKeyValueStorage())

        await coding.save(isSignedIn: true)

        #expect(await coding.loadSignedInState() == true)
    }

    @Test
    func `저장한 값이 없으면 nil을 돌려준다`() async {
        let coding = SharedSessionStateMarkerCoding(storage: InMemoryKeyValueStorage())

        #expect(await coding.loadSignedInState() == nil)
    }

    @Test
    func `schemaVersion이 1이 아닌 값은 nil로 조회한다`() async {
        let storage = InMemoryKeyValueStorage()
        await storage.setValue(
            UnknownMarker(schemaVersion: 2, isSignedIn: true, updatedAt: Date()),
            forKey: SharedSessionStateMarkerCoding.stateMarkerKey,
        )
        let coding = SharedSessionStateMarkerCoding(storage: storage)

        #expect(await coding.loadSignedInState() == nil)
    }

    @Test
    func `로그인 상태를 stateMarker key에 저장한다`() async {
        let storage = InMemoryKeyValueStorage()
        let coding = SharedSessionStateMarkerCoding(storage: storage)

        await coding.save(isSignedIn: false)

        #expect(storage.storedData(forKey: "stateMarker") != nil)
    }

    // MARK: Private

    private struct UnknownMarker: Codable, Sendable {
        let schemaVersion: Int
        let isSignedIn: Bool
        let updatedAt: Date
    }

}
