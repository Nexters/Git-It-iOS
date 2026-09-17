import DataMember
import DataShared
import DomainMember

// MARK: - DeviceIdentifierRepositoryAdapter

public struct DeviceIdentifierRepositoryAdapter: DeviceIdentifierRepository {

    // MARK: Lifecycle

    public init(secureStorage: any SecureValueStorage) {
        store = LocalDeviceIdentifierStore(storage: secureStorage)
    }

    // MARK: Public

    public func currentDeviceID() async -> String {
        store.loadOrCreate()
    }

    // MARK: Private

    private let store: LocalDeviceIdentifierStore

}
