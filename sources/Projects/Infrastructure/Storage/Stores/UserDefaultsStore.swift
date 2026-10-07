import Foundation

public actor UserDefaultsStore {

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
        _ data: Data,
        forKey key: String,
    ) {
        userDefaults.set(data, forKey: storageKey(for: key))
    }

    public func value(forKey key: String) -> Data? {
        userDefaults.data(forKey: storageKey(for: key))
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
