import Foundation
import Testing

@testable import DataShared
@testable import InfrastructureAuthentication

// MARK: - LocalSecureValueStorageTests

@Suite("LocalSecureValueStorage")
struct LocalSecureValueStorageTests {

    @Test
    func `namespace와 key 자리에 값을 저장하고 다시 읽는다`() throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        let storage = LocalSecureValueStorage(
            namespace: "test.namespace",
            keychainStore: keychainStore,
        )

        try storage.setData(
            Data("value".utf8),
            forKey: "key",
        )

        #expect(try storage.data(forKey: "key") == Data("value".utf8))
        #expect(try keychainStore.load(
            for: "key",
            in: KeychainNamespace("test.namespace"),
        ) == Data("value".utf8))
    }

    @Test
    func `다른 namespace의 값은 읽지 않는다`() throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        try keychainStore.save(
            Data("other".utf8),
            for: "key",
            in: KeychainNamespace("test.other"),
        )
        let storage = LocalSecureValueStorage(
            namespace: "test.namespace",
            keychainStore: keychainStore,
        )

        #expect(try storage.data(forKey: "key") == nil)
    }

    @Test
    func `삭제하면 값을 읽을 수 없다`() throws {
        let storage = LocalSecureValueStorage(
            namespace: "test.namespace",
            keychainStore: KeychainStore(backend: KeychainStore.InMemoryBackend()),
        )
        try storage.setData(
            Data("value".utf8),
            forKey: "key",
        )

        try storage.removeData(forKey: "key")

        #expect(try storage.data(forKey: "key") == nil)
    }

}
