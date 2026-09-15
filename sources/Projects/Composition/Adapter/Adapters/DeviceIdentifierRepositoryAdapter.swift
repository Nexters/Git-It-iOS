import DataMember
import DomainMember
import InfrastructureAuthentication

// MARK: - DeviceIdentifierRepositoryAdapter

public struct DeviceIdentifierRepositoryAdapter: DeviceIdentifierRepository {

    // MARK: Lifecycle

    public init(keychainStore: KeychainStore) {
        store = LocalDeviceIdentifierStore(keychainStore: keychainStore)
    }

    // MARK: Public

    public func currentDeviceID() async -> String {
        store.loadOrCreate()
    }

    // MARK: Private

    private let store: LocalDeviceIdentifierStore

}
