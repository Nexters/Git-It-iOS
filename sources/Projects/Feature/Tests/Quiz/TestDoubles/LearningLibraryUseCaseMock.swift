import DomainLearningProject

actor LearningLibraryUseCaseMock: LearningLibraryUseCase {

    // MARK: Lifecycle

    init(
        detailResults: [Result<LearningProjectDetail, LearningProjectError>] = [.failure(.unexpected)],
        deleteResults: [Result<Void, LearningProjectError>] = [.success(())],
        setResults: [Result<LearningSet, LearningProjectError>] = [.failure(.unexpected)],
        bookmarkResults: [Result<BookmarkedQuestionCollection, LearningProjectError>] = [.failure(.unexpected)],
    ) {
        self.detailResults = detailResults
        self.deleteResults = deleteResults
        self.setResults = setResults
        self.bookmarkResults = bookmarkResults
    }

    // MARK: Internal

    private(set) var requestedProjectIDs = [String]()
    private(set) var deletedProjectIDs = [String]()
    private(set) var requestedSetIDs = [String]()
    private(set) var requestedBookmarkProjectIDs = [String?]()

    func project(id: String) async throws -> LearningProjectDetail {
        requestedProjectIDs.append(id)
        return try Self.next(&detailResults, fallback: .failure(.unexpected)).get()
    }

    func deleteProject(id: String) async throws {
        deletedProjectIDs.append(id)
        try Self.next(&deleteResults, fallback: .failure(.unexpected)).get()
    }

    func learningSet(
        projectID _: String,
        setID: String,
    ) async throws -> LearningSet {
        requestedSetIDs.append(setID)
        return try Self.next(&setResults, fallback: .failure(.unexpected)).get()
    }

    func bookmarkedQuestions(projectID: String?) async throws -> BookmarkedQuestionCollection {
        requestedBookmarkProjectIDs.append(projectID)
        return try Self.next(&bookmarkResults, fallback: .failure(.unexpected)).get()
    }

    // MARK: Private

    private var detailResults: [Result<LearningProjectDetail, LearningProjectError>]
    private var deleteResults: [Result<Void, LearningProjectError>]
    private var setResults: [Result<LearningSet, LearningProjectError>]
    private var bookmarkResults: [Result<BookmarkedQuestionCollection, LearningProjectError>]

    private static func next<Value>(
        _ results: inout [Result<Value, LearningProjectError>],
        fallback: Result<Value, LearningProjectError>,
    ) -> Result<Value, LearningProjectError> {
        guard !results.isEmpty else { return fallback }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
