import Foundation
import InfrastructureStorage

// MARK: - PendingGenerationReminderCoding

/// Share Extension이 남기고 본 앱의 리마인더 조정자가 흡수하는 대기 목록을 다룬다.
/// 이 목록은 미완료 등록 요청의 큐가 아니라 이미 성공한 등록의 알림 대상 목록이다.
public struct PendingGenerationReminderCoding: Sendable {

    // MARK: Lifecycle

    public init(userDefaults: UserDefaults) {
        store = UserDefaultsStore<[Entry]>(
            namespace: SharedSessionLayout.namespace,
            userDefaults: userDefaults,
        )
    }

    // MARK: Public

    /// 이미 있는 프로젝트는 다시 추가하지 않고, 상한을 넘으면 오래된 항목부터 버린다.
    public func append(
        projectID: String,
        requestedAt: Date = Date(),
    ) async {
        var entries = await loadEntries()
        guard !entries.contains(where: { $0.projectID == projectID }) else { return }
        entries.append(
            Entry(
                projectID: projectID,
                requestedAt: requestedAt,
            )
        )
        if entries.count > SharedSessionLayout.pendingReminderLimit {
            entries.removeFirst(entries.count - SharedSessionLayout.pendingReminderLimit)
        }
        await store.store(
            entries,
            forKey: SharedSessionLayout.pendingGenerationRemindersKey,
        )
    }

    /// 목록을 읽고 비운다. 읽은 항목의 소유권은 호출자로 넘어간다.
    public func drainProjectIDs() async -> [String] {
        let entries = await loadEntries()
        guard !entries.isEmpty else { return [] }
        await store.removeValue(forKey: SharedSessionLayout.pendingGenerationRemindersKey)
        return entries.map(\.projectID)
    }

    // MARK: Private

    private struct Entry: Codable, Sendable {
        let projectID: String
        let requestedAt: Date
    }

    private let store: UserDefaultsStore<[Entry]>

    /// 디코딩에 실패하면 빈 목록으로 취급한다. 손상된 값이 등록 흐름을 막지 않는다.
    private func loadEntries() async -> [Entry] {
        await store.value(forKey: SharedSessionLayout.pendingGenerationRemindersKey) ?? []
    }

}
