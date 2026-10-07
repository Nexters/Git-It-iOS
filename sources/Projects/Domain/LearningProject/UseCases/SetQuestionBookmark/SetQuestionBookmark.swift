import Foundation

// MARK: - SetQuestionBookmark

public actor SetQuestionBookmark: SetQuestionBookmarkUseCase {

    // MARK: Lifecycle

    public init(repository: any BookmarkRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(
        projectID: String,
        questionID: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState {
        let repository = repository
        return try await serialize(key: questionID) {
            try await repository.setBookmark(
                projectID: projectID,
                questionID: questionID,
                bookmarked: bookmarked,
            )
        }
    }

    // MARK: Internal

    var pendingKeyCount: Int {
        inFlight.count
    }

    // MARK: Private

    private struct PendingMutation {
        let token: UUID
        let awaitCompletion: @Sendable () async -> Void
    }

    private let repository: any BookmarkRepository

    private var inFlight = [String: PendingMutation]()

    private func serialize<Value: Sendable>(
        key: String,
        _ operation: @escaping @Sendable () async throws -> Value,
    ) async throws -> Value {
        let token = UUID()
        let previous = inFlight[key]

        let task = Task<Value, Error> {
            await previous?.awaitCompletion()
            return try await operation()
        }
        inFlight[key] = PendingMutation(token: token, awaitCompletion: { _ = try? await task.value })

        defer {
            if inFlight[key]?.token == token {
                inFlight[key] = nil
            }
        }

        return try await task.value
    }

}
