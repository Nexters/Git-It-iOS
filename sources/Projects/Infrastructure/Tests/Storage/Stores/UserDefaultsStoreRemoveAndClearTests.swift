import Foundation
import Testing
@testable import InfrastructureStorage

@Suite("UserDefaultsStore 제거와 전체 비우기")
struct UserDefaultsStoreRemoveAndClearTests {

    @Test
    func `키를 제거한 뒤 조회하면 nil이 반환된다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore(
            namespace: "test",
            userDefaults: userDefaults,
        )
        await store.store(
            Data("V".utf8),
            forKey: "A",
        )

        await store.removeValue(forKey: "A")

        #expect(await store.value(forKey: "A") == nil)
    }

    @Test
    func `전체 비우기 뒤 같은 namespace의 모든 키가 nil을 반환한다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore(
            namespace: "test",
            userDefaults: userDefaults,
        )
        await store.store(
            Data("V1".utf8),
            forKey: "A",
        )
        await store.store(
            Data("V2".utf8),
            forKey: "B",
        )

        await store.removeAll()

        #expect(await store.value(forKey: "A") == nil)
        #expect(await store.value(forKey: "B") == nil)
    }

    @Test
    func `전체 비우기는 다른 namespace의 값에 영향을 주지 않는다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let storeA = UserDefaultsStore(
            namespace: "namespaceA",
            userDefaults: userDefaults,
        )
        let storeB = UserDefaultsStore(
            namespace: "namespaceB",
            userDefaults: userDefaults,
        )
        await storeA.store(
            Data("A값".utf8),
            forKey: "키",
        )
        await storeB.store(
            Data("B값".utf8),
            forKey: "키",
        )

        await storeA.removeAll()

        #expect(await storeA.value(forKey: "키") == nil)
        #expect(await storeB.value(forKey: "키") == Data("B값".utf8))
    }

    @Test
    func `존재하지 않는 키를 제거해도 오류 없이 완료된다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore(
            namespace: "test",
            userDefaults: userDefaults,
        )

        await store.removeValue(forKey: "존재하지-않는-키")

        #expect(await store.value(forKey: "존재하지-않는-키") == nil)
    }

    @Test
    func `저장된 적 없는 키를 조회해도 오류·예외 없이 nil이 반환된다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore(
            namespace: "test",
            userDefaults: userDefaults,
        )

        #expect(await store.value(forKey: "저장된-적-없는-키") == nil)
    }

    @Test
    func `저장된 바이트를 해석하지 않고 그대로 반환한다`() async throws {
        let suiteName = "UserDefaultsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsStore(
            namespace: "test",
            userDefaults: userDefaults,
        )
        userDefaults.set(
            Data([0xFF, 0x00, 0xAB]),
            forKey: "test.원시-키",
        )

        #expect(await store.value(forKey: "원시-키") == Data([0xFF, 0x00, 0xAB]))
    }

}
