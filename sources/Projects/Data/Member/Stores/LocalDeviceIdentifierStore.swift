import Foundation
import InfrastructureAuthentication

// MARK: - LocalDeviceIdentifierStore

public struct LocalDeviceIdentifierStore: Sendable {

    // MARK: Lifecycle

    public init(keychainStore: KeychainStore) {
        self.keychainStore = keychainStore
    }

    // MARK: Public

    public static let namespace = KeychainNamespace("com.nexters.hytime.gitit.device")
    public static let key = "deviceID"

    public func loadOrCreate() -> String {
        if
            let data = try? keychainStore.load(for: Self.key, in: Self.namespace),
            let existing = String(data: data, encoding: .utf8)
        {
            return existing
        }
        let newDeviceID = UUID().uuidString
        if let data = newDeviceID.data(using: .utf8) {
            try? keychainStore.save(data, for: Self.key, in: Self.namespace)
        }
        return newDeviceID
    }

    // MARK: Private

    private let keychainStore: KeychainStore

}
