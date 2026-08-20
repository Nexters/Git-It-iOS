import DomainLearningProject

struct SampleDeleteLearningProject: DeleteLearningProjectUseCase {
    init(store: SampleLearningProjectStore) {
        self.store = store
    }

    func callAsFunction(projectId: String) async throws {
        try await store.delete(projectId: projectId)
    }

    private let store: SampleLearningProjectStore
}
