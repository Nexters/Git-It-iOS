import Foundation
import InfrastructureAuthentication
import InfrastructureStorage

// MARK: - StorageFactory

public enum StorageFactory {

    // MARK: Public

    public static func keyValueStorage(
        namespace: String,
        location: StorageLocation,
    ) -> any KeyValueStorage {
        keyValueStorage(namespace: namespace, userDefaults: userDefaults(for: location))
    }

    public static func secureValueStorage(
        namespace: String,
        location: StorageLocation,
    ) -> any SecureValueStorage {
        LocalSecureValueStorage(namespace: namespace, keychainStore: keychainStore(for: location))
    }

    // MARK: Internal

    static func keyValueStorage(
        namespace: String,
        userDefaults: UserDefaults?,
    ) -> any KeyValueStorage {
        guard let userDefaults else { return UnavailableKeyValueStorage() }
        return LocalKeyValueStorage(namespace: namespace, userDefaults: userDefaults)
    }

    // MARK: Private

    private static func keychainStore(for location: StorageLocation) -> KeychainStore {
        switch location {
        case .appGroup:
            AppGroupKeychainStore.makeShared()
        case .device:
            KeychainStore()
        }
    }

    private static func userDefaults(for location: StorageLocation) -> UserDefaults? {
        switch location {
        case .appGroup:
            AppGroupUserDefaults.makeShared()
        case .device:
            .standard
        }
    }

}
