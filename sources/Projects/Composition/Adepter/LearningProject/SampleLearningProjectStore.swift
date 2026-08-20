import DomainLearningProject

// MARK: - SampleLearningProjectStore

actor SampleLearningProjectStore {

    // MARK: Lifecycle

    init(initialPage: LearningProjectPage) {
        currentPage = initialPage
    }

    // MARK: Internal

    func page() -> LearningProjectPage {
        currentPage
    }

    func delete(projectId: String) throws {
        guard let index = currentPage.items.firstIndex(where: { $0.projectId == projectId }) else {
            throw LearningProjectError.notFound
        }

        var items = currentPage.items
        items.remove(at: index)
        currentPage = LearningProjectPage(
            items: items,
            hasNext: currentPage.hasNext,
        )
    }

    // MARK: Private

    private var currentPage: LearningProjectPage

}
