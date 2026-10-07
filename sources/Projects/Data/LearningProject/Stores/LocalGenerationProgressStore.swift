import InfrastructureStorage

public struct LocalGenerationProgressStore: GenerationProgressStore {

    // MARK: Lifecycle

    public init(store: UserDefaultsStore<GenerationProgressDTO>) {
        self.store = store
    }

    // MARK: Public

    public func load() async -> GenerationProgressDTO? {
        await store.value(forKey: Self.progressKey)
    }

    public func save(_ progress: GenerationProgressDTO) async {
        await store.store(progress, forKey: Self.progressKey)
    }

    public func clear() async {
        await store.removeValue(forKey: Self.progressKey)
    }

    // MARK: Private

    private static let progressKey = "progress"

    private let store: UserDefaultsStore<GenerationProgressDTO>

}
