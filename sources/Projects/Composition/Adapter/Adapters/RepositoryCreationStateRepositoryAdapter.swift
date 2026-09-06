import DomainLearningProject
import Foundation
import InfrastructureStorage

// MARK: - RepositoryCreationStateRepositoryAdapter

actor RepositoryCreationStateRepositoryAdapter: RepositoryCreationStateRepository {

    // MARK: Lifecycle

    init(
        userDefaults: UserDefaults = .standard,
        clock: @escaping @Sendable () -> Date = Date.init,
    ) {
        store = UserDefaultsStore(namespace: SharedSessionLayout.namespace, userDefaults: userDefaults)
        self.clock = clock
    }

    // MARK: Internal

    func isCreating(githubRepoURL: String) async -> Bool {
        let records = await purgeExpired()
        return records[normalize(githubRepoURL)] != nil
    }

    func beginCreation(githubRepoURL: String) async -> Bool {
        var records = await purgeExpired()
        let key = normalize(githubRepoURL)
        guard records[key] == nil else { return false }
        records[key] = RepositoryCreationState(normalizedGithubRepoURL: key, recordedAt: clock())
        await save(records)
        return true
    }

    func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async {
        var records = await purgeExpired()
        records[normalize(githubRepoURL)]?.projectID = projectID
        await save(records)
    }

    func endCreation(githubRepoURL: String) async {
        var records = await loadRecords()
        records.removeValue(forKey: normalize(githubRepoURL))
        await save(records)
    }

    func endCreation(projectID: String) async {
        var records = await loadRecords()
        guard let key = records.first(where: { $0.value.projectID == projectID })?.key else { return }
        records.removeValue(forKey: key)
        await save(records)
    }

    func activeProjectIDs() async -> Set<String> {
        let records = await purgeExpired()
        return Set(records.values.compactMap(\.projectID))
    }

    func start(observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase) async {
        let outcomes = await observeGenerationOutcomes()
        observationTask = Task {
            for await outcome in outcomes {
                await self.endCreation(projectID: outcome.projectID)
            }
        }
    }

    // MARK: Private

    private static let expiryInterval: TimeInterval = 900
    private static let recordsKey = SharedSessionLayout.repositoryCreationStatesKey

    private let store: UserDefaultsStore<[String: RepositoryCreationState]>
    private let clock: @Sendable () -> Date
    private var observationTask: Task<Void, Never>?

    private func normalize(_ githubRepoURL: String) -> String {
        var normalized = githubRepoURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
    }

    private func loadRecords() async -> [String: RepositoryCreationState] {
        await store.value(forKey: Self.recordsKey) ?? [:]
    }

    private func purgeExpired() async -> [String: RepositoryCreationState] {
        let now = clock()
        let records = await loadRecords().filter { now.timeIntervalSince($0.value.recordedAt) < Self.expiryInterval }
        await save(records)
        return records
    }

    private func save(_ records: [String: RepositoryCreationState]) async {
        if records.isEmpty {
            await store.removeValue(forKey: Self.recordsKey)
        } else {
            await store.store(records, forKey: Self.recordsKey)
        }
    }

}
