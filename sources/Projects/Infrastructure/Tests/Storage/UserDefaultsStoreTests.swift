import Foundation
import Testing

@testable import InfrastructureCache

@Suite("UserDefaultsStore 저장과 조회")
struct UserDefaultsStoreStoreAndRetrieveTests {

    @Test
    func `Codable 값을 저장한 직후 같은 키로 조회하면 저장한 값이 그대로 반환된다`() async {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)

        await store.store("V", forKey: "A")

        #expect(await store.value(forKey: "A") == "V")
    }

    @Test
    func `같은 키에 값을 다시 저장하면 이전 값이 아닌 새 값이 반환된다`() async {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)
        await store.store("V1", forKey: "A")

        await store.store("V2", forKey: "A")

        #expect(await store.value(forKey: "A") == "V2")
    }

    @Test
    func `서로 다른 namespace의 같은 키는 값을 공유하지 않는다`() async {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let storeA = UserDefaultsStore<String>(namespace: "namespaceA", userDefaults: userDefaults)
        let storeB = UserDefaultsStore<String>(namespace: "namespaceB", userDefaults: userDefaults)

        await storeA.store("A값", forKey: "동일한-키")
        await storeB.store("B값", forKey: "동일한-키")

        #expect(await storeA.value(forKey: "동일한-키") == "A값")
        #expect(await storeB.value(forKey: "동일한-키") == "B값")
    }

    @Test
    func `같은 namespace 안에서 서로 다른 키는 값을 공유하지 않는다`() async {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)

        await store.store("V1", forKey: "A")
        await store.store("V2", forKey: "B")

        #expect(await store.value(forKey: "A") == "V1")
        #expect(await store.value(forKey: "B") == "V2")
    }

}

@Suite("UserDefaultsStore 제거와 전체 비우기")
struct UserDefaultsStoreRemoveAndClearTests {

    @Test
    func `키를 제거한 뒤 조회하면 nil이 반환된다`() async {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)
        await store.store("V", forKey: "A")

        await store.removeValue(forKey: "A")

        #expect(await store.value(forKey: "A") == nil)
    }

    @Test
    func `전체 비우기 뒤 같은 namespace의 모든 키가 nil을 반환한다`() async {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)
        await store.store("V1", forKey: "A")
        await store.store("V2", forKey: "B")

        await store.removeAll()

        #expect(await store.value(forKey: "A") == nil)
        #expect(await store.value(forKey: "B") == nil)
    }

    @Test
    func `전체 비우기는 다른 namespace의 값에 영향을 주지 않는다`() async {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let storeA = UserDefaultsStore<String>(namespace: "namespaceA", userDefaults: userDefaults)
        let storeB = UserDefaultsStore<String>(namespace: "namespaceB", userDefaults: userDefaults)
        await storeA.store("A값", forKey: "키")
        await storeB.store("B값", forKey: "키")

        await storeA.removeAll()

        #expect(await storeA.value(forKey: "키") == nil)
        #expect(await storeB.value(forKey: "키") == "B값")
    }

    @Test
    func `존재하지 않는 키를 제거해도 오류 없이 완료된다`() async {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)

        await store.removeValue(forKey: "존재하지-않는-키")

        #expect(await store.value(forKey: "존재하지-않는-키") == nil)
    }

    @Test
    func `저장된 적 없는 키를 조회해도 오류·예외 없이 nil이 반환된다`() async {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)

        #expect(await store.value(forKey: "저장된-적-없는-키") == nil)
    }

    @Test
    func `손상된 raw 값을 디코딩하지 못해도 오류 없이 nil이 반환된다`() async {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore<String>(namespace: "test", userDefaults: userDefaults)
        userDefaults.set(Data([0xFF, 0x00, 0xAB]), forKey: "test.손상된-키")

        #expect(await store.value(forKey: "손상된-키") == nil)
    }

}
