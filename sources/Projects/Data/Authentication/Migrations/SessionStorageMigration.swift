import Foundation
import InfrastructureAuthentication

// MARK: - SessionStorageMigration

public struct SessionStorageMigration: Sendable {

    // MARK: Lifecycle

    public init(
        sharedKeychainStore: KeychainStore,
        legacyKeychainStore: KeychainStore,
    ) {
        sharedCoding = SessionRecordStorageCoding(keychainStore: sharedKeychainStore)
        legacyCoding = SessionRecordStorageCoding(keychainStore: legacyKeychainStore)
    }

    // MARK: Public

    public enum Outcome: Equatable, Sendable {
        case migrated
        case alreadyMigrated
        case nothingToMigrate
        case failed
    }

    @discardableResult
    public func callAsFunction() -> Outcome {
        if (try? sharedCoding.load()) != nil {
            return .alreadyMigrated
        }
        guard let legacyRecord = try? legacyCoding.load() else {
            return .nothingToMigrate
        }
        do {
            try sharedCoding.save(legacyRecord)
        } catch {
            return .failed
        }
        try? legacyCoding.delete()
        return .migrated
    }

    // MARK: Private

    private let sharedCoding: SessionRecordStorageCoding
    private let legacyCoding: SessionRecordStorageCoding

}
