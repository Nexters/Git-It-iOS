import InfrastructureStorage

public actor LocalGenerationStateStore: GenerationStateStore {

    // MARK: Lifecycle

    public init(
        store: UserDefaultsStore<GenerationStateDTO>,
        migration: GenerationStateMigration? = nil,
    ) {
        self.store = store
        self.migration = migration
    }

    // MARK: Public

    public func load() async -> GenerationStateDTO {
        if let stored = await store.value(forKey: Self.stateKey) {
            hasAttemptedMigration = true
            return stored
        }
        guard !hasAttemptedMigration else { return GenerationStateDTO(records: []) }
        hasAttemptedMigration = true
        guard let migrated = await migration?.migratedState() else {
            return GenerationStateDTO(records: [])
        }
        await store.store(migrated, forKey: Self.stateKey)
        return migrated
    }

    public func save(_ state: GenerationStateDTO) async {
        hasAttemptedMigration = true
        await store.store(state, forKey: Self.stateKey)
    }

    // MARK: Private

    private static let stateKey = "generationState"

    private let store: UserDefaultsStore<GenerationStateDTO>
    private let migration: GenerationStateMigration?
    private var hasAttemptedMigration = false

}
