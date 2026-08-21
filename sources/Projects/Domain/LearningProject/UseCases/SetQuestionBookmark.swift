import Foundation

// MARK: - SetQuestionBookmark

/// UC09 — desired final bool을 전송하고 서버 응답을 정본으로 반영한다. 같은 question에
/// 대한 동시 호출은 `QuestionMutationSerializer`가 직렬화한다.
public struct SetQuestionBookmark: SetQuestionBookmarkUseCase {

    // MARK: Lifecycle

    public init(
        repository: BookmarkRepository,
        serializer: QuestionMutationSerializer = QuestionMutationSerializer(),
    ) {
        self.repository = repository
        self.serializer = serializer
    }

    // MARK: Public

    public func callAsFunction(
        projectID: String,
        questionID: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState {
        try await serializer.run(key: questionID) {
            try await repository.setBookmark(
                projectID: projectID,
                questionID: questionID,
                bookmarked: bookmarked,
            )
        }
    }

    // MARK: Private

    private let repository: BookmarkRepository
    private let serializer: QuestionMutationSerializer

}

// MARK: - QuestionMutationSerializer

/// question별 mutation을 직렬화하는 actor. 같은 key(questionID)의 호출은 순차 실행되고,
/// 서로 다른 key는 독립적으로 실행된다.
public actor QuestionMutationSerializer {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func run<Value: Sendable>(
        key: String,
        _ operation: @escaping @Sendable () async throws -> Value,
    ) async throws -> Value {
        let token = UUID()
        let previous = inFlight[key]

        let task = Task<Value, Error> {
            _ = await previous?.awaitCompletion()
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

    // MARK: Private

    private struct PendingMutation {
        let token: UUID
        let awaitCompletion: @Sendable () async -> Void
    }

    private var inFlight = [String: PendingMutation]()

}
