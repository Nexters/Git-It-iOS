import DomainLearningProject
import Foundation

// MARK: - RepositoryCreationStateRepositoryAdapter

actor RepositoryCreationStateRepositoryAdapter: RepositoryCreationStateRepository {

    // MARK: Lifecycle

    init(clock: @escaping @Sendable () -> Date = Date.init) {
        self.clock = clock
    }

    // MARK: Internal

    func isCreating(githubRepoURL: String) async -> Bool {
        purgeExpired()
        return records[normalize(githubRepoURL)] != nil
    }

    func beginCreation(githubRepoURL: String) async -> Bool {
        purgeExpired()
        let key = normalize(githubRepoURL)
        guard records[key] == nil else { return false }
        records[key] = RepositoryCreationState(normalizedGithubRepoURL: key, recordedAt: clock())
        return true
    }

    func attachProjectID(_ projectID: String, toGithubRepoURL githubRepoURL: String) async {
        purgeExpired()
        records[normalize(githubRepoURL)]?.projectID = projectID
    }

    func endCreation(githubRepoURL: String) async {
        records.removeValue(forKey: normalize(githubRepoURL))
    }

    func endCreation(projectID: String) async {
        guard let key = records.first(where: { $0.value.projectID == projectID })?.key else { return }
        records.removeValue(forKey: key)
    }

    func activeProjectIDs() async -> Set<String> {
        purgeExpired()
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

    private let clock: @Sendable () -> Date
    private var records = [String: RepositoryCreationState]()
    private var observationTask: Task<Void, Never>?

    private func normalize(_ githubRepoURL: String) -> String {
        var normalized = githubRepoURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
    }

    private func purgeExpired() {
        let now = clock()
        records = records.filter { now.timeIntervalSince($0.value.recordedAt) < Self.expiryInterval }
    }

}
