import Foundation
import InfrastructureStorage

// MARK: - LocalKeyValueStorage

struct LocalKeyValueStorage: KeyValueStorage {

    // MARK: Lifecycle

    init(store: UserDefaultsStore) {
        self.store = store
    }

    // MARK: Internal

    func value<Value: Codable & Sendable>(
        _: Value.Type,
        forKey key: String,
    ) async -> Value? {
        guard let data = await store.value(forKey: key) else { return nil }
        return try? JSONDecoder().decode(
            Value.self,
            from: data,
        )
    }

    func verifiedValue<Value: Codable & Sendable>(
        _: Value.Type,
        forKey key: String,
    ) async throws(KeyValueStorageError) -> Value? {
        guard let data = await store.value(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(
                Value.self,
                from: data,
            )
        } catch {
            throw .unreadable
        }
    }

    func setValue(
        _ value: some Codable & Sendable,
        forKey key: String,
    ) async {
        guard let data = try? JSONEncoder().encode(value) else { return }
        await store.store(
            data,
            forKey: key,
        )
    }

    func removeValue(forKey key: String) async {
        await store.removeValue(forKey: key)
    }

    func removeAllValues() async {
        await store.removeAll()
    }

    // MARK: Private

    private let store: UserDefaultsStore

}
