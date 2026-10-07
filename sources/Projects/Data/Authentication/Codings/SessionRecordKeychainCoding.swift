import Foundation
import InfrastructureAuthentication

// MARK: - SessionRecordKeychainCoding

public struct SessionRecordKeychainCoding: Sendable {

    // MARK: Lifecycle

    public init(keychainStore: KeychainStore) {
        self.keychainStore = keychainStore
    }

    // MARK: Public

    public func load() throws -> StoredSessionRecord? {
        guard let data = try keychainStore.load(for: key, in: namespace) else { return nil }
        return try JSONDecoder().decode(StoredSessionRecord.self, from: data)
    }

    public func save(_ record: StoredSessionRecord) throws {
        let data = try JSONEncoder().encode(record)
        try keychainStore.save(data, for: key, in: namespace)
    }

    public func delete() throws {
        try keychainStore.delete(for: key, in: namespace)
    }

    // MARK: Private

    private let keychainStore: KeychainStore
    private let key = SessionKeychainLayout.Key.sessionRecord.rawValue
    private let namespace = SessionKeychainLayout.namespace

}
