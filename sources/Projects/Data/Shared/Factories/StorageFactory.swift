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
        keyValueStorage(store: userDefaultsStore(
            namespace: namespace,
            location: location,
        ))
    }

    public static func secureValueStorage(
        namespace: String,
        location: StorageLocation,
    ) -> any SecureValueStorage {
        LocalSecureValueStorage(
            namespace: namespace,
            keychainStore: keychainStore(for: location),
        )
    }

    // MARK: Internal

    static func keyValueStorage(store: UserDefaultsStore?) -> any KeyValueStorage {
        guard let store else { return UnavailableKeyValueStorage() }
        return LocalKeyValueStorage(store: store)
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

    private static func userDefaultsStore(
        namespace: String,
        location: StorageLocation,
    ) -> UserDefaultsStore? {
        switch location {
        case .appGroup:
            AppGroupUserDefaults.makeShared().map {
                UserDefaultsStore(
                    namespace: namespace,
                    userDefaults: $0,
                )
            }

        case .device:
            UserDefaultsStore(namespace: namespace)
        }
    }

}
