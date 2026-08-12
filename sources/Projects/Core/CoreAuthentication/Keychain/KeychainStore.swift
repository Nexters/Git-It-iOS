import Foundation
import Security
import Synchronization

// MARK: - KeychainStore

public final class KeychainStore: Sendable {

    // MARK: Lifecycle

    public init() {
        backend = nil
    }

    init(backend: InMemoryBackend) {
        self.backend = backend
    }

    // MARK: Public

    public final class InMemoryBackend: Sendable {

        // MARK: Public

        public var accessibility: KeychainAccessibility? {
            state.withLock { $0.accessibility }
        }

        // MARK: Fileprivate

        fileprivate func save(
            _ value: Data,
            key: String,
            namespace: KeychainNamespace,
        ) {
            state.withLock { state in
                state.accessibility = .whenUnlockedThisDeviceOnly
                state.values["\(namespace.rawValue).\(key)"] = value
            }
        }

        fileprivate func load(
            key: String,
            namespace: KeychainNamespace,
        ) -> Data? {
            state.withLock { $0.values["\(namespace.rawValue).\(key)"] }
        }

        fileprivate func delete(
            key: String,
            namespace: KeychainNamespace,
        ) {
            _ = state.withLock { $0.values.removeValue(forKey: "\(namespace.rawValue).\(key)") }
        }

        // MARK: Private

        private struct State {
            var accessibility: KeychainAccessibility?
            var values = [String: Data]()
        }

        private let state = Mutex(State())

    }

    public func save(
        _ value: Data,
        for key: String,
        in namespace: KeychainNamespace,
    ) throws {
        if let backend {
            backend.save(value, key: key, namespace: namespace)
            return
        }
        let query = attributes(key: key, namespace: namespace)
        let update: [CFString: Any] = [kSecValueData: value]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData] = value
            item[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw KeychainStoreError.unavailable }
        } else if status != errSecSuccess {
            throw KeychainStoreError.unavailable
        }
    }

    public func load(
        for key: String,
        in namespace: KeychainNamespace,
    ) throws -> Data? {
        if let backend {
            return backend.load(key: key, namespace: namespace)
        }
        var query = attributes(key: key, namespace: namespace)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let value = result as? Data else { throw KeychainStoreError.unavailable }
        return value
    }

    public func delete(
        for key: String,
        in namespace: KeychainNamespace,
    ) throws {
        if let backend {
            backend.delete(key: key, namespace: namespace)
            return
        }
        let status = SecItemDelete(attributes(key: key, namespace: namespace) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainStoreError.unavailable }
    }

    // MARK: Private

    private let backend: InMemoryBackend?

    private func attributes(
        key: String,
        namespace: KeychainNamespace,
    ) -> [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: namespace.rawValue, kSecAttrAccount: key]
    }

}
