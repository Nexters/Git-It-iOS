// MARK: - KeyValueStorage

public protocol KeyValueStorage: Sendable {
    func value<Value: Codable & Sendable>(_ type: Value.Type, forKey key: String) async -> Value?
    func setValue<Value: Codable & Sendable>(_ value: Value, forKey key: String) async
    func removeValue(forKey key: String) async
    func removeAllValues() async
}
