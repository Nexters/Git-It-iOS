import Foundation
import Testing
@testable import DataMember

// MARK: - LocalDeviceIdentifierStoreTests

@Suite("LocalDeviceIdentifierStore")
struct LocalDeviceIdentifierStoreTests {

    @Test
    func `두 번 조회해도 같은 기기 식별자를 돌려준다`() {
        let store = LocalDeviceIdentifierStore(storage: InMemorySecureValueStorage())

        let first = store.loadOrCreate()

        #expect(store.loadOrCreate() == first)
        #expect(!first.isEmpty)
    }

    @Test
    func `기기 식별자는 기존 Keychain 네임스페이스와 키를 그대로 쓴다`() throws {
        let storage = InMemorySecureValueStorage()
        let store = LocalDeviceIdentifierStore(storage: storage)

        let deviceID = store.loadOrCreate()

        #expect(LocalDeviceIdentifierStore.namespace == "com.nexters.hytime.gitit.device")
        let stored = try #require(storage.storedData(forKey: "deviceID"))
        #expect(String(
            data: stored,
            encoding: .utf8,
        ) == deviceID)
    }

}
