import DomainUseCaseInterface

actor QuizDetailUseCaseBookmarkListStub {

    // MARK: Lifecycle

    init(results: [Result<QuizBookmarkList, QuizDetailError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var callCount = 0
    private(set) var requestedFilters = [QuizBookmarkFilter]()

    nonisolated var fetchBookmarks: @Sendable (QuizBookmarkFilter) async throws -> QuizBookmarkList {
        { try await self(filter: $0) }
    }

    func callAsFunction(filter: QuizBookmarkFilter) async throws -> QuizBookmarkList {
        callCount += 1
        requestedFilters.append(filter)
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<QuizBookmarkList, QuizDetailError>]

    private func nextResult() -> Result<QuizBookmarkList, QuizDetailError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
