import InfrastructureStorage

public actor LocalGenerationStateStore: GenerationStateStore {

    // MARK: Lifecycle

    public init(store: UserDefaultsStore<GenerationStateDTO>) {
        self.store = store
    }

    // MARK: Public

    public func load() async -> GenerationStateDTO {
        await store.value(forKey: Self.stateKey) ?? GenerationStateDTO(records: [])
    }

    public func save(_ state: GenerationStateDTO) async {
        await store.store(state, forKey: Self.stateKey)
    }

    // MARK: Private

    private static let stateKey = "generationState"

    private let store: UserDefaultsStore<GenerationStateDTO>

}
