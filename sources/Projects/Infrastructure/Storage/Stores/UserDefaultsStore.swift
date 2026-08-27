import Foundation

public actor UserDefaultsStore<Value: Codable & Sendable> {

    // MARK: Lifecycle

    public init(
        namespace: String,
        userDefaults: UserDefaults = .standard,
    ) {
        self.namespace = namespace
        self.userDefaults = userDefaults
    }

    // MARK: Public

    public func store(
        _ value: Value,
        forKey key: String,
    ) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        userDefaults.set(data, forKey: storageKey(for: key))
    }

    public func value(forKey key: String) -> Value? {
        guard let data = userDefaults.data(forKey: storageKey(for: key)) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    public func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: storageKey(for: key))
    }

    public func removeAll() {
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(keyPrefix) {
            userDefaults.removeObject(forKey: key)
        }
    }

    // MARK: Private

    private let namespace: String
    private let userDefaults: UserDefaults

    private var keyPrefix: String {
        "\(namespace)."
    }

    private func storageKey(for key: String) -> String {
        "\(keyPrefix)\(key)"
    }

}
