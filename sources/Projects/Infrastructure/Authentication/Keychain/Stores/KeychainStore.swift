import Foundation
import Security
import Synchronization

// MARK: - KeychainStore

public final class KeychainStore: Sendable {

    // MARK: Lifecycle

    public init(accessGroup: KeychainAccessGroup? = nil) {
        backend = nil
        self.accessGroup = accessGroup
    }

    init(
        backend: InMemoryBackend,
        accessGroup: KeychainAccessGroup? = nil,
    ) {
        self.backend = backend
        self.accessGroup = accessGroup
    }

    // MARK: Public

    public final class InMemoryBackend: Sendable {

        // MARK: Public

        public var accessibility: KeychainAccessibility? {
            state.withLock { $0.accessibility }
        }

        public var accessGroups: Set<String> {
            state.withLock { $0.accessGroups }
        }

        // MARK: Fileprivate

        fileprivate func save(
            _ value: Data,
            key: String,
            namespace: KeychainNamespace,
            accessGroup: KeychainAccessGroup?,
            accessibility: KeychainAccessibility,
        ) {
            state.withLock { state in
                let storageKey = Self.storageKey(
                    key: key,
                    namespace: namespace,
                    accessGroup: accessGroup,
                )
                if state.values[storageKey] == nil {
                    state.accessibility = accessibility
                }
                if let accessGroup {
                    state.accessGroups.insert(accessGroup.rawValue)
                }
                state.values[storageKey] = value
            }
        }

        fileprivate func load(
            key: String,
            namespace: KeychainNamespace,
            accessGroup: KeychainAccessGroup?,
        ) -> Data? {
            state.withLock {
                $0.values[Self.storageKey(
                    key: key,
                    namespace: namespace,
                    accessGroup: accessGroup,
                )]
            }
        }

        fileprivate func delete(
            key: String,
            namespace: KeychainNamespace,
            accessGroup: KeychainAccessGroup?,
        ) {
            _ = state.withLock {
                $0.values.removeValue(forKey: Self.storageKey(
                    key: key,
                    namespace: namespace,
                    accessGroup: accessGroup,
                ))
            }
        }

        fileprivate func removeAll() {
            state.withLock { $0.values.removeAll() }
        }

        // MARK: Private

        private struct State {
            var accessibility: KeychainAccessibility?
            var accessGroups = Set<String>()
            var values = [String: Data]()
        }

        private let state = Mutex(State())

        private static func storageKey(
            key: String,
            namespace: KeychainNamespace,
            accessGroup: KeychainAccessGroup?,
        ) -> String {
            "\(accessGroup?.rawValue ?? "").\(namespace.rawValue).\(key)"
        }

    }

    public func save(
        _ value: Data,
        for key: String,
        in namespace: KeychainNamespace,
    ) throws {
        if let backend {
            backend.save(
                value,
                key: key,
                namespace: namespace,
                accessGroup: accessGroup,
                accessibility: Self.accessibilityForNewItem,
            )
            return
        }
        let query = attributes(
            key: key,
            namespace: namespace,
        )
        let update: [CFString: Any] = [kSecValueData: value]
        let status = SecItemUpdate(
            query as CFDictionary,
            update as CFDictionary,
        )
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData] = value
            item[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard
                SecItemAdd(
                    item as CFDictionary,
                    nil,
                ) == errSecSuccess
            else { throw KeychainStoreError.unavailable }
        } else if status != errSecSuccess {
            throw KeychainStoreError.unavailable
        }
    }

    public func load(
        for key: String,
        in namespace: KeychainNamespace,
    ) throws -> Data? {
        if let backend {
            return backend.load(
                key: key,
                namespace: namespace,
                accessGroup: accessGroup,
            )
        }
        var query = attributes(
            key: key,
            namespace: namespace,
        )
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result,
        )
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
            backend.delete(
                key: key,
                namespace: namespace,
                accessGroup: accessGroup,
            )
            return
        }
        let status = SecItemDelete(attributes(
            key: key,
            namespace: namespace,
        ) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainStoreError.unavailable }
    }

    public func removeAll() throws {
        if let backend {
            backend.removeAll()
            return
        }
        var query: [CFString: Any] = [kSecClass: kSecClassGenericPassword]
        if let accessGroup {
            query[kSecAttrAccessGroup] = accessGroup.rawValue
        }
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainStoreError.unavailable }
    }

    // MARK: Private

    private static let accessibilityForNewItem = KeychainAccessibility.afterFirstUnlockThisDeviceOnly

    private let backend: InMemoryBackend?
    private let accessGroup: KeychainAccessGroup?

    private func attributes(
        key: String,
        namespace: KeychainNamespace,
    ) -> [CFString: Any] {
        var attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: namespace.rawValue,
            kSecAttrAccount: key,
        ]
        if let accessGroup {
            attributes[kSecAttrAccessGroup] = accessGroup.rawValue
        }
        return attributes
    }

}
