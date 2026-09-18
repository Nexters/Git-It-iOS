import Foundation
import InfrastructureStorage

// MARK: - LocalKeyValueStorage

struct LocalKeyValueStorage: KeyValueStorage {

    // MARK: Lifecycle

    init(
        namespace: String,
        userDefaults: UserDefaults,
    ) {
        self.namespace = namespace
        self.userDefaults = userDefaults
    }

    // MARK: Internal

    func value<Value: Codable & Sendable>(
        _: Value.Type,
        forKey key: String,
    ) async -> Value? {
        await store(of: Value.self).value(forKey: key)
    }

    func setValue<Value: Codable & Sendable>(
        _ value: Value,
        forKey key: String,
    ) async {
        await store(of: Value.self).store(value, forKey: key)
    }

    func removeValue(forKey key: String) async {
        await store(of: Data.self).removeValue(forKey: key)
    }

    func removeAllValues() async {
        await store(of: Data.self).removeAll()
    }

    // MARK: Private

    private let namespace: String
    private let userDefaults: UserDefaults

    private func store<Value: Codable & Sendable>(of _: Value.Type) -> UserDefaultsStore<Value> {
        UserDefaultsStore(namespace: namespace, userDefaults: userDefaults)
    }

}
