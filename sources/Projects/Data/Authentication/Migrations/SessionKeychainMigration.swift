import Foundation
import InfrastructureAuthentication

// MARK: - SessionKeychainMigration

public struct SessionKeychainMigration: Sendable {

    // MARK: Lifecycle

    public init(
        sharedKeychainStore: KeychainStore,
        legacyKeychainStore: KeychainStore,
    ) {
        sharedCoding = SessionRecordKeychainCoding(keychainStore: sharedKeychainStore)
        legacyCoding = SessionRecordKeychainCoding(keychainStore: legacyKeychainStore)
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

    private let sharedCoding: SessionRecordKeychainCoding
    private let legacyCoding: SessionRecordKeychainCoding

}
