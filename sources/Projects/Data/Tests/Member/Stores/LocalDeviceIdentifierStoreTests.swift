import Foundation
import Testing
@testable import DataMember
@testable import InfrastructureAuthentication

// MARK: - LocalDeviceIdentifierStoreTests

@Suite("LocalDeviceIdentifierStore")
struct LocalDeviceIdentifierStoreTests {

    @Test
    func `두 번 조회해도 같은 기기 식별자를 돌려준다`() {
        let store = LocalDeviceIdentifierStore(keychainStore: KeychainStore(backend: KeychainStore.InMemoryBackend()))

        let first = store.loadOrCreate()

        #expect(store.loadOrCreate() == first)
        #expect(!first.isEmpty)
    }

    @Test
    func `기기 식별자는 기존 Keychain 네임스페이스와 키를 그대로 쓴다`() throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let store = LocalDeviceIdentifierStore(keychainStore: keychainStore)

        let deviceID = store.loadOrCreate()

        let stored = try #require(try keychainStore.load(
            for: "deviceID",
            in: KeychainNamespace("com.nexters.hytime.gitit.device"),
        ))
        #expect(String(data: stored, encoding: .utf8) == deviceID)
    }

}
