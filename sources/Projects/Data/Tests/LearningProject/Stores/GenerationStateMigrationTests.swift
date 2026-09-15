import Foundation
import InfrastructureStorage
import Testing

@testable import DataLearningProject

@Suite("GenerationStateMigration")
struct GenerationStateMigrationTests {

    @Test
    func `레거시 값이 없으면 이관하지 않는다`() async {
        let migration = GenerationStateMigration(
            legacyProgressStore: Self.makeProgressStore(),
            legacyCreationStateStore: Self.makeCreationStateStore(),
        )
        #expect(await migration.migratedState() == nil)
    }

    @Test
    func `레거시 등록 상태만 있으면 저장소 URL을 가진 진행 중 기록으로 옮긴다`() async {
        let creationStore = Self.makeCreationStateStore()
        await creationStore.store(
            ["https://github.com/owner/repo": Self.creationState(projectID: "p1")],
            forKey: GenerationStateMigration.legacyCreationStateKey,
        )
        let migration = GenerationStateMigration(
            legacyProgressStore: Self.makeProgressStore(),
            legacyCreationStateStore: creationStore,
        )

        let migrated = await migration.migratedState()

        #expect(migrated?.records.count == 1)
        #expect(migrated?.records.first?.githubRepoURL == "https://github.com/owner/repo")
        #expect(migrated?.records.first?.projectID == "p1")
        #expect(migrated?.records.first?.status == "inProgress")
        #expect(await creationStore.value(forKey: GenerationStateMigration.legacyCreationStateKey) == nil)
    }

    @Test
    func `레거시 진행 정보만 있으면 URL이 빈 진행 중 기록으로 옮긴다`() async {
        let progressStore = Self.makeProgressStore()
        await progressStore.store(
            LegacyGenerationProgressDTO(projectID: "p1", requestedAt: Self.requestedAt),
            forKey: GenerationStateMigration.legacyProgressKey,
        )
        let migration = GenerationStateMigration(
            legacyProgressStore: progressStore,
            legacyCreationStateStore: Self.makeCreationStateStore(),
        )

        let migrated = await migration.migratedState()

        #expect(migrated?.records.count == 1)
        #expect(migrated?.records.first?.projectID == "p1")
        #expect(migrated?.records.first?.githubRepoURL.isEmpty == true)
        #expect(await progressStore.value(forKey: GenerationStateMigration.legacyProgressKey) == nil)
    }

    @Test
    func `같은 프로젝트 식별자가 양쪽에 있으면 등록 상태의 URL을 채택하고 기록을 하나만 남긴다`() async {
        let progressStore = Self.makeProgressStore()
        await progressStore.store(
            LegacyGenerationProgressDTO(projectID: "p1", requestedAt: Self.requestedAt),
            forKey: GenerationStateMigration.legacyProgressKey,
        )
        let creationStore = Self.makeCreationStateStore()
        await creationStore.store(
            ["https://github.com/owner/repo": Self.creationState(projectID: "p1")],
            forKey: GenerationStateMigration.legacyCreationStateKey,
        )
        let migration = GenerationStateMigration(
            legacyProgressStore: progressStore,
            legacyCreationStateStore: creationStore,
        )

        let migrated = await migration.migratedState()

        #expect(migrated?.records.count == 1)
        #expect(migrated?.records.first?.githubRepoURL == "https://github.com/owner/repo")
    }

    @Test
    func `이관한 상태를 새 키에 저장하고 두 번째 불러오기에서는 다시 이관하지 않는다`() async {
        let creationStore = Self.makeCreationStateStore()
        await creationStore.store(
            ["https://github.com/owner/repo": Self.creationState(projectID: "p1")],
            forKey: GenerationStateMigration.legacyCreationStateKey,
        )
        let store = LocalGenerationStateStore(
            store: LocalGenerationStateStoreTests.makeStore(),
            migration: GenerationStateMigration(
                legacyProgressStore: Self.makeProgressStore(),
                legacyCreationStateStore: creationStore,
            ),
        )

        let first = await store.load()
        let second = await store.load()

        #expect(first.records.count == 1)
        #expect(second == first)
    }

    // MARK: Private

    private static let requestedAt = Date(timeIntervalSince1970: 1_000)

    private static func makeDefaults() -> UserDefaults {
        let suiteName = "test.generationStateMigration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private static func makeProgressStore() -> UserDefaultsStore<LegacyGenerationProgressDTO> {
        UserDefaultsStore(namespace: "legacy.progress", userDefaults: makeDefaults())
    }

    private static func makeCreationStateStore() -> UserDefaultsStore<[String: LegacyRepositoryCreationStateDTO]> {
        UserDefaultsStore(namespace: "legacy.creationState", userDefaults: makeDefaults())
    }

    private static func creationState(projectID: String?) -> LegacyRepositoryCreationStateDTO {
        LegacyRepositoryCreationStateDTO(
            normalizedGithubRepoURL: "https://github.com/owner/repo",
            projectID: projectID,
            recordedAt: requestedAt,
        )
    }

}
