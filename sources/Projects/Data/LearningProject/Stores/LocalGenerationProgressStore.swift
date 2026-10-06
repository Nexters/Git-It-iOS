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
        // 단일 키만 사용해 진행 중인 생성이 언제나 1건만 남게 한다.
        await store.store(progress, forKey: Self.progressKey)
    }

    public func clear() async {
        await store.removeValue(forKey: Self.progressKey)
    }

    // MARK: Private

    private static let progressKey = "progress"

    private let store: UserDefaultsStore<GenerationProgressDTO>

}
