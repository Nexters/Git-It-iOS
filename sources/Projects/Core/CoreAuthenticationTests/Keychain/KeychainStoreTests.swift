import Foundation
import Testing

@testable import CoreAuthentication

@Suite("KeychainStore")
struct KeychainStoreTests {
    @Test
    func `namespace별 기기 한정 접근성으로 원자적 CRUD를 수행한다`() throws {
        let backend = KeychainStore.InMemoryBackend()
        let store = KeychainStore(backend: backend)
        let session = KeychainNamespace("session")
        let authorization = KeychainNamespace("authorization")

        try store.save(
            Data([1]),
            for: "token",
            in: session,
        )
        try store.save(
            Data([2]),
            for: "token",
            in: authorization,
        )
        #expect(try store.load(
            for: "token",
            in: session,
        ) == Data([1]))
        #expect(try store.load(
            for: "token",
            in: authorization,
        ) == Data([2]))
        #expect(backend.accessibility == .whenUnlockedThisDeviceOnly)
        try store.delete(
            for: "token",
            in: session,
        )
        #expect(try store.load(
            for: "token",
            in: session,
        ) == nil)
    }
}
