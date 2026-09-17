import Foundation
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

    // MARK: Internal

    static func keyValueStorage(
        namespace: String,
        userDefaults: UserDefaults?,
    ) -> any KeyValueStorage {
        guard let userDefaults else { return UnavailableKeyValueStorage() }
        return LocalKeyValueStorage(namespace: namespace, userDefaults: userDefaults)
    }

    // MARK: Private

    private static func userDefaults(for location: StorageLocation) -> UserDefaults? {
        switch location {
        case .appGroup:
            AppGroupUserDefaults.makeShared()
        case .device:
            .standard
        }
    }

}
