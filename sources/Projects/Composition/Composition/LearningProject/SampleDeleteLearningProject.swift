import DomainLearningProject

struct SampleDeleteLearningProject: DeleteLearningProject {
    init(store: SampleLearningProjectStore) {
        self.store = store
    }

    func callAsFunction(_ id: LearningProjectID) async throws {
        try await store.delete(id)
    }

    private let store: SampleLearningProjectStore
}
