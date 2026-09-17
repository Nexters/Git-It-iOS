import DataMember
import DataShared
import DomainAppSetting

// MARK: - DeviceIdentifierRepositoryAdapter

public struct DeviceIdentifierRepositoryAdapter: DeviceIdentifierRepository {

    // MARK: Lifecycle

    public init(secureStorage: any SecureValueStorage) {
        store = LocalDeviceIdentifierStore(storage: secureStorage)
    }

    // MARK: Public

    public func currentDeviceID() async -> DeviceID {
        store.loadOrCreate()
    }

    // MARK: Private

    private let store: LocalDeviceIdentifierStore

}
