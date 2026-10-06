import DataLearningProject
import DomainLearningProject

// MARK: - GenerationProgressRepositoryAdapter

struct GenerationProgressRepositoryAdapter: GenerationProgressRepository {

    // MARK: Lifecycle

    init(store: any GenerationProgressStore) {
        self.store = store
    }

    // MARK: Internal

    func load() async -> GenerationProgress? {
        await store.load().map { GenerationProgress(projectID: $0.projectID, requestedAt: $0.requestedAt) }
    }

    func save(_ progress: GenerationProgress) async {
        await store.save(GenerationProgressDTO(projectID: progress.projectID, requestedAt: progress.requestedAt))
    }

    func clear() async {
        await store.clear()
    }

    // MARK: Private

    private let store: any GenerationProgressStore

}
