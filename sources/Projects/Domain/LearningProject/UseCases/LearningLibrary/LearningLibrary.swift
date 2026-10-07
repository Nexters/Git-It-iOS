// MARK: - LearningLibrary

public struct LearningLibrary: LearningLibraryUseCase {

    // MARK: Lifecycle

    public init(
        projectRepository: any LearningProjectRepository,
        learningSetRepository: any LearningSetRepository,
        bookmarkRepository: any BookmarkRepository,
    ) {
        self.projectRepository = projectRepository
        self.learningSetRepository = learningSetRepository
        self.bookmarkRepository = bookmarkRepository
    }

    // MARK: Public

    public func project(id: String) async throws -> LearningProjectDetail {
        try await projectRepository.fetchProjectDetail(projectID: id)
    }

    public func deleteProject(id: String) async throws {
        try await projectRepository.deleteProject(projectID: id)
    }

    public func learningSet(
        projectID: String,
        setID: String,
    ) async throws -> LearningSet {
        try await learningSetRepository.fetchSet(projectID: projectID, setID: setID)
    }

    public func bookmarkedQuestions(projectID: String?) async throws -> BookmarkedQuestionCollection {
        try await bookmarkRepository.fetchBookmarkedQuestions(projectID: projectID)
    }

    // MARK: Private

    private let projectRepository: any LearningProjectRepository
    private let learningSetRepository: any LearningSetRepository
    private let bookmarkRepository: any BookmarkRepository

}
