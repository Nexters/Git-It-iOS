// MARK: - KeyValueStorage

public protocol KeyValueStorage: Sendable {
    func value<Value: Codable & Sendable>(
        _ type: Value.Type,
        forKey key: String,
    ) async -> Value?
    func verifiedValue<Value: Codable & Sendable>(
        _ type: Value.Type,
        forKey key: String,
    ) async throws(KeyValueStorageError) -> Value?
    func setValue(
        _ value: some Codable & Sendable,
        forKey key: String,
    ) async
    func removeValue(forKey key: String) async
    func removeAllValues() async
}
