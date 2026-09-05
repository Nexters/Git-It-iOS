import Foundation
import InfrastructureAuthentication

// MARK: - SessionKeychainMigration

/// 접근 그룹이 없던 기존 세션 항목을 공유 접근 그룹으로 옮긴다. 본 앱만 수행하며
/// 실패하면 기존 항목을 남겨 사용자가 로그아웃되지 않게 한다.
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
        // 저장에 성공한 뒤에만 기존 항목을 제거한다. 삭제가 실패해도 공유 항목이 이미
        // 있으므로 다음 실행에서 이전 완료로 판정된다.
        try? legacyCoding.delete()
        return .migrated
    }

    // MARK: Private

    private let sharedCoding: SessionRecordKeychainCoding
    private let legacyCoding: SessionRecordKeychainCoding

}
