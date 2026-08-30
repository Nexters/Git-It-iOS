import Foundation
import Testing
@testable import InfrastructureStorage

struct UserDefaultsStoreStoreAndRetrieveTests {

    @Test
    func `Codable 값을 저장한 직후 같은 키로 조회하면 저장한 값이 그대로 반환된다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)

        await store.store("V", forKey: "A")

        #expect(await store.value(forKey: "A") == "V")
    }

    @Test
    func `같은 키에 값을 다시 저장하면 이전 값이 아닌 새 값이 반환된다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)
        await store.store("V1", forKey: "A")

        await store.store("V2", forKey: "A")

        #expect(await store.value(forKey: "A") == "V2")
    }

    @Test
    func `서로 다른 namespace의 같은 키는 값을 공유하지 않는다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let storeA = UserDefaultsStore<String>(namespace: "namespaceA", userDefaults: userDefaults)
        let storeB = UserDefaultsStore<String>(namespace: "namespaceB", userDefaults: userDefaults)

        await storeA.store("A값", forKey: "동일한-키")
        await storeB.store("B값", forKey: "동일한-키")

        #expect(await storeA.value(forKey: "동일한-키") == "A값")
        #expect(await storeB.value(forKey: "동일한-키") == "B값")
    }

    @Test
    func `같은 namespace 안에서 서로 다른 키는 값을 공유하지 않는다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)

        await store.store("V1", forKey: "A")
        await store.store("V2", forKey: "B")

        #expect(await store.value(forKey: "A") == "V1")
        #expect(await store.value(forKey: "B") == "V2")
    }

}
