import Foundation
import Testing

@testable import InfrastructureAuthentication

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
        #expect(backend.accessibility == .afterFirstUnlockThisDeviceOnly)
        try store.delete(
            for: "token",
            in: session,
        )
        #expect(try store.load(
            for: "token",
            in: session,
        ) == nil)
    }

    @Test
    func `접근 그룹을 지정하면 같은 그룹의 항목만 읽는다`() throws {
        let backend = KeychainStore.InMemoryBackend()
        let namespace = KeychainNamespace("session")
        let sharedGroup = KeychainAccessGroup("group.shared")
        let sharedStore = KeychainStore(
            backend: backend,
            accessGroup: sharedGroup,
        )
        let ungroupedStore = KeychainStore(backend: backend)

        try ungroupedStore.save(
            Data([1]),
            for: "record",
            in: namespace,
        )
        #expect(try sharedStore.load(
            for: "record",
            in: namespace,
        ) == nil)

        try sharedStore.save(
            Data([2]),
            for: "record",
            in: namespace,
        )
        #expect(try sharedStore.load(
            for: "record",
            in: namespace,
        ) == Data([2]))
        #expect(try ungroupedStore.load(
            for: "record",
            in: namespace,
        ) == Data([1]))
        #expect(backend.accessGroups == [sharedGroup.rawValue])
    }

    @Test
    func `이미 저장된 항목을 갱신해도 접근성은 신규 저장 시점의 값을 유지한다`() throws {
        let backend = KeychainStore.InMemoryBackend()
        let store = KeychainStore(backend: backend)
        let namespace = KeychainNamespace("session")

        try store.save(
            Data([1]),
            for: "record",
            in: namespace,
        )
        try store.save(
            Data([2]),
            for: "record",
            in: namespace,
        )

        #expect(try store.load(
            for: "record",
            in: namespace,
        ) == Data([2]))
        #expect(backend.accessibility == .afterFirstUnlockThisDeviceOnly)
    }
}
