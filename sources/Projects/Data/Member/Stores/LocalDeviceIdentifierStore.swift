import DataShared
import Foundation

// MARK: - LocalDeviceIdentifierStore

public struct LocalDeviceIdentifierStore: Sendable {

    // MARK: Lifecycle

    public init(storage: any SecureValueStorage) {
        self.storage = storage
    }

    // MARK: Public

    public static let namespace = "com.nexters.hytime.gitit.device"
    public static let key = "deviceID"

    public func loadOrCreate() -> String {
        if
            let data = try? storage.data(forKey: Self.key),
            let existing = String(
                data: data,
                encoding: .utf8,
            )
        {
            return existing
        }
        let newDeviceID = UUID().uuidString
        try? storage.setData(
            Data(newDeviceID.utf8),
            forKey: Self.key,
        )
        return newDeviceID
    }

    // MARK: Private

    private let storage: any SecureValueStorage

}
