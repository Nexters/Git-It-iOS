import DataShared
import Foundation
import Synchronization

// MARK: - InMemoryKeyValueStorage

final class InMemoryKeyValueStorage: KeyValueStorage {

    // MARK: Lifecycle

    init(verificationFailure: KeyValueStorageError? = nil) {
        self.verificationFailure = verificationFailure
    }

    // MARK: Internal

    func value<Value: Codable & Sendable>(
        _: Value.Type,
        forKey key: String,
    ) async -> Value? {
        guard let data = values.withLock({ $0[key] }) else { return nil }
        return try? JSONDecoder().decode(
            Value.self,
            from: data,
        )
    }

    func verifiedValue<Value: Codable & Sendable>(
        _: Value.Type,
        forKey key: String,
    ) async throws(KeyValueStorageError) -> Value? {
        if let verificationFailure {
            throw verificationFailure
        }
        guard let data = values.withLock({ $0[key] }) else { return nil }
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
        values.withLock { $0[key] = data }
    }

    func removeValue(forKey key: String) async {
        values.withLock { $0[key] = nil }
    }

    func removeAllValues() async {
        values.withLock { $0.removeAll() }
    }

    func storedData(forKey key: String) -> Data? {
        values.withLock { $0[key] }
    }

    // MARK: Private

    private let verificationFailure: KeyValueStorageError?
    private let values = Mutex<[String: Data]>([:])

}
