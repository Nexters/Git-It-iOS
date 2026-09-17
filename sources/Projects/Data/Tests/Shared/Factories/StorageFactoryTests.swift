import Foundation
import Testing

@testable import DataShared

// MARK: - StorageFactoryTests

@Suite("StorageFactory")
struct StorageFactoryTests {

    // MARK: Internal

    @Test
    func `App Group 저장소를 만들 수 없으면 기록을 무시하고 조회에 nil을 돌려준다`() async {
        let storage = StorageFactory.keyValueStorage(namespace: "test.namespace", userDefaults: nil)

        await storage.setValue(Sample(name: "value"), forKey: "sample")

        #expect(await storage.value(Sample.self, forKey: "sample") == nil)
    }

    @Test
    func `저장소가 있으면 기록한 값을 다시 조회한다`() async throws {
        let userDefaults = try #require(UserDefaults(suiteName: "StorageFactoryTests.\(UUID().uuidString)"))
        let storage = StorageFactory.keyValueStorage(namespace: "test.namespace", userDefaults: userDefaults)

        await storage.setValue(Sample(name: "value"), forKey: "sample")

        #expect(await storage.value(Sample.self, forKey: "sample") == Sample(name: "value"))
    }

    // MARK: Private

    private struct Sample: Codable, Equatable, Sendable {
        let name: String
    }

}
