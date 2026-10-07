import Foundation
import Testing
@testable import InfrastructureStorage

struct UserDefaultsStoreStoreAndRetrieveTests {

    @Test
    func `바이트 값을 저장한 직후 같은 키로 조회하면 저장한 바이트가 그대로 반환된다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore(namespace: "test", userDefaults: userDefaults)

        await store.store(Data("V".utf8), forKey: "A")

        #expect(await store.value(forKey: "A") == Data("V".utf8))
    }

    @Test
    func `같은 키에 값을 다시 저장하면 이전 값이 아닌 새 값이 반환된다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore(namespace: "test", userDefaults: userDefaults)
        await store.store(Data("V1".utf8), forKey: "A")

        await store.store(Data("V2".utf8), forKey: "A")

        #expect(await store.value(forKey: "A") == Data("V2".utf8))
    }

    @Test
    func `namespace와 키를 점으로 이은 UserDefaults 키에 저장한다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore(namespace: "test.namespace", userDefaults: userDefaults)

        await store.store(Data("V".utf8), forKey: "A")

        #expect(userDefaults.data(forKey: "test.namespace.A") == Data("V".utf8))
    }

    @Test
    func `서로 다른 namespace의 같은 키는 값을 공유하지 않는다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let storeA = UserDefaultsStore(namespace: "namespaceA", userDefaults: userDefaults)
        let storeB = UserDefaultsStore(namespace: "namespaceB", userDefaults: userDefaults)

        await storeA.store(Data("A값".utf8), forKey: "동일한-키")
        await storeB.store(Data("B값".utf8), forKey: "동일한-키")

        #expect(await storeA.value(forKey: "동일한-키") == Data("A값".utf8))
        #expect(await storeB.value(forKey: "동일한-키") == Data("B값".utf8))
    }

    @Test
    func `같은 namespace 안에서 서로 다른 키는 값을 공유하지 않는다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore(namespace: "test", userDefaults: userDefaults)

        await store.store(Data("V1".utf8), forKey: "A")
        await store.store(Data("V2".utf8), forKey: "B")

        #expect(await store.value(forKey: "A") == Data("V1".utf8))
        #expect(await store.value(forKey: "B") == Data("V2".utf8))
    }

}
