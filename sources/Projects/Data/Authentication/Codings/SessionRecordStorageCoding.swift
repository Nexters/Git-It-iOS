import DataShared
import Foundation

// MARK: - SessionRecordStorageCoding

public struct SessionRecordStorageCoding: Sendable {

    // MARK: Lifecycle

    public init(storage: any SecureValueStorage) {
        self.storage = storage
    }

    // MARK: Public

    public func load() throws -> StoredSessionRecord? {
        guard let data = try storage.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(StoredSessionRecord.self, from: data)
    }

    public func save(_ record: StoredSessionRecord) throws {
        let data = try JSONEncoder().encode(record)
        try storage.setData(data, forKey: key)
    }

    public func delete() throws {
        try storage.removeData(forKey: key)
    }

    // MARK: Private

    private let storage: any SecureValueStorage
    private let key = SessionStorageLayout.Key.sessionRecord.rawValue

}
