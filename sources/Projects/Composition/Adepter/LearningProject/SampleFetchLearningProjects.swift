import DomainLearningProject

struct SampleFetchLearningProjects: FetchLearningProjects {
    init(store: SampleLearningProjectStore) {
        self.store = store
    }

    func callAsFunction(
        page _: Int,
        size _: Int,
    ) async throws -> LearningProjectPage {
        await store.page()
    }

    private let store: SampleLearningProjectStore
}
