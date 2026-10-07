import Foundation
import InfrastructureAuthentication

// MARK: - LocalSecureValueStorage

struct LocalSecureValueStorage: SecureValueStorage {

    // MARK: Lifecycle

    init(
        namespace: String,
        keychainStore: KeychainStore,
    ) {
        self.namespace = KeychainNamespace(namespace)
        self.keychainStore = keychainStore
    }

    // MARK: Internal

    func data(forKey key: String) throws(SecureValueStorageError) -> Data? {
        do {
            return try keychainStore.load(for: key, in: namespace)
        } catch {
            throw .unavailable
        }
    }

    func setData(
        _ data: Data,
        forKey key: String,
    ) throws(SecureValueStorageError) {
        do {
            try keychainStore.save(data, for: key, in: namespace)
        } catch {
            throw .unavailable
        }
    }

    func removeData(forKey key: String) throws(SecureValueStorageError) {
        do {
            try keychainStore.delete(for: key, in: namespace)
        } catch {
            throw .unavailable
        }
    }

    // MARK: Private

    private let namespace: KeychainNamespace
    private let keychainStore: KeychainStore

}
