import Foundation
import Testing

@testable import DataShared

// MARK: - LocalKeyValueStorageTests

@Suite("LocalKeyValueStorage")
struct LocalKeyValueStorageTests {

    // MARK: Internal

    @Test
    func `namespace와 key를 이은 키에 값을 JSON으로 저장한다`() async throws {
        let (storage, userDefaults) = try makeStorage(namespace: "test.namespace")

        await storage.setValue(Sample(name: "value", count: 3), forKey: "sample")

        let data = try #require(userDefaults.data(forKey: "test.namespace.sample"))
        #expect(try JSONDecoder().decode(Sample.self, from: data) == Sample(name: "value", count: 3))
    }

    @Test
    func `저장한 값을 같은 타입으로 다시 조회한다`() async throws {
        let (storage, _) = try makeStorage(namespace: "test.namespace")

        await storage.setValue(Sample(name: "value", count: 3), forKey: "sample")

        #expect(await storage.value(Sample.self, forKey: "sample") == Sample(name: "value", count: 3))
    }

    @Test
    func `값을 삭제하면 조회 결과가 없다`() async throws {
        let (storage, _) = try makeStorage(namespace: "test.namespace")
        await storage.setValue(Sample(name: "value", count: 3), forKey: "sample")

        await storage.removeValue(forKey: "sample")

        #expect(await storage.value(Sample.self, forKey: "sample") == nil)
    }

    @Test
    func `전체 삭제는 같은 namespace의 값만 지운다`() async throws {
        let (storage, userDefaults) = try makeStorage(namespace: "test.namespace")
        let other = LocalKeyValueStorage(namespace: "test.other", userDefaults: userDefaults)
        await storage.setValue(Sample(name: "mine", count: 1), forKey: "sample")
        await other.setValue(Sample(name: "other", count: 2), forKey: "sample")

        await storage.removeAllValues()

        #expect(await storage.value(Sample.self, forKey: "sample") == nil)
        #expect(await other.value(Sample.self, forKey: "sample") == Sample(name: "other", count: 2))
    }

    // MARK: Private

    private struct Sample: Codable, Equatable, Sendable {
        let name: String
        let count: Int
    }

    private func makeStorage(namespace: String) throws -> (LocalKeyValueStorage, UserDefaults) {
        let suiteName = "LocalKeyValueStorageTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        return (LocalKeyValueStorage(namespace: namespace, userDefaults: userDefaults), userDefaults)
    }

}
