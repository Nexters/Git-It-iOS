// MARK: - UnavailableKeyValueStorage

struct UnavailableKeyValueStorage: KeyValueStorage {
    func value<Value: Codable & Sendable>(_: Value.Type, forKey _: String) async -> Value? {
        nil
    }

    func setValue(_: some Codable & Sendable, forKey _: String) async {}

    func removeValue(forKey _: String) async {}

    func removeAllValues() async {}
}
