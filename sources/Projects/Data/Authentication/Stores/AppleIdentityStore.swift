import Foundation
import InfrastructureAuthentication

// MARK: - AppleIdentityStore

public struct AppleIdentityStore: Sendable {

    // MARK: Lifecycle

    public init(keychainStore: KeychainStore) {
        self.keychainStore = keychainStore
    }

    // MARK: Public

    public func load() throws -> String? {
        guard let data = try keychainStore.load(for: key, in: namespace) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func save(_ userID: String) throws {
        try keychainStore.save(Data(userID.utf8), for: key, in: namespace)
    }

    public func delete() throws {
        try keychainStore.delete(for: key, in: namespace)
    }

    // MARK: Private

    private let keychainStore: KeychainStore
    private let key = AppleIdentityStorageLayout.Key.appleUserID.rawValue
    private let namespace = AppleIdentityStorageLayout.namespace

}
