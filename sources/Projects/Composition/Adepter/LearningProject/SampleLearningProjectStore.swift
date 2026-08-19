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

    func delete(_ id: LearningProjectID) throws {
        guard let index = currentPage.projects.firstIndex(where: { $0.id == id }) else {
            throw LearningProjectError.projectUnavailable
        }

        var projects = currentPage.projects
        projects.remove(at: index)
        currentPage = LearningProjectPage(
            projects: projects,
            hasNextPage: currentPage.hasNextPage,
        )
    }

    // MARK: Private

    private var currentPage: LearningProjectPage

}
