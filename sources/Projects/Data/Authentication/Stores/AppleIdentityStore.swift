import DataShared
import Foundation

// MARK: - AppleIdentityStore

public struct AppleIdentityStore: Sendable {

    // MARK: Lifecycle

    public init(storage: any SecureValueStorage) {
        self.storage = storage
    }

    // MARK: Public

    public func load() throws -> String? {
        guard let data = try storage.data(forKey: key) else { return nil }
        return String(
            data: data,
            encoding: .utf8,
        )
    }

    public func save(_ userID: String) throws {
        try storage.setData(
            Data(userID.utf8),
            forKey: key,
        )
    }

    public func delete() throws {
        try storage.removeData(forKey: key)
    }

    // MARK: Private

    private let storage: any SecureValueStorage
    private let key = AppleIdentityStorageLayout.Key.appleUserID.rawValue

}
