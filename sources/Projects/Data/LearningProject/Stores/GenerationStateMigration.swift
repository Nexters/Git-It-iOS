import Foundation
import InfrastructureStorage

public struct GenerationStateMigration: Sendable {

    // MARK: Lifecycle

    public init(
        legacyProgressStore: UserDefaultsStore<LegacyGenerationProgressDTO>?,
        legacyCreationStateStore: UserDefaultsStore<[String: LegacyRepositoryCreationStateDTO]>?,
    ) {
        self.legacyProgressStore = legacyProgressStore
        self.legacyCreationStateStore = legacyCreationStateStore
    }

    // MARK: Public

    public static let legacyProgressNamespace = "com.nexters.hytime.gitit.generationProgress"
    public static let legacyProgressKey = "progress"
    public static let legacyCreationStateKey = "repositoryCreationStates"

    public func migratedState() async -> GenerationStateDTO? {
        let creationStates = await legacyCreationStateStore?.value(forKey: Self.legacyCreationStateKey)
        let progress = await legacyProgressStore?.value(forKey: Self.legacyProgressKey)
        guard creationStates != nil || progress != nil else { return nil }

        var records = (creationStates ?? [:]).values.map { state in
            GenerationRecordDTO(
                githubRepoURL: state.normalizedGithubRepoURL,
                projectID: state.projectID,
                requestedAt: state.recordedAt,
                status: Self.inProgressStatus,
                finishedAt: nil,
            )
        }

        if
            let progress,
            !records.contains(where: { $0.projectID == progress.projectID })
        {
            records.append(GenerationRecordDTO(
                githubRepoURL: "",
                projectID: progress.projectID,
                requestedAt: progress.requestedAt,
                status: Self.inProgressStatus,
                finishedAt: nil,
            ))
        }

        await clearLegacy()
        return GenerationStateDTO(records: records.sorted { $0.requestedAt < $1.requestedAt })
    }

    // MARK: Private

    private static let inProgressStatus = "inProgress"

    private let legacyProgressStore: UserDefaultsStore<LegacyGenerationProgressDTO>?
    private let legacyCreationStateStore: UserDefaultsStore<[String: LegacyRepositoryCreationStateDTO]>?

    private func clearLegacy() async {
        await legacyProgressStore?.removeValue(forKey: Self.legacyProgressKey)
        await legacyCreationStateStore?.removeValue(forKey: Self.legacyCreationStateKey)
    }

}
