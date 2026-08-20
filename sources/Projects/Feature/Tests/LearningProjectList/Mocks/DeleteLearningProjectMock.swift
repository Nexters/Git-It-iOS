import DomainLearningProject

actor DeleteLearningProjectMock: DeleteLearningProjectUseCase {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior

        if case .pending = behavior {
            let pair = AsyncThrowingStream<Void, Error>.makeStream()
            pendingStream = pair.stream
            pendingContinuation = pair.continuation
        } else {
            pendingStream = nil
            pendingContinuation = nil
        }
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case result(Result<Void, LearningProjectError>)
        case pending
    }

    func callAsFunction(projectId: String) async throws {
        projectIDs.append(projectId)

        switch behavior {
        case .result(.success):
            return

        case .result(.failure(let error)):
            throw error

        case .pending:
            guard let pendingStream else {
                throw CancellationError()
            }

            for try await _ in pendingStream {
                return
            }
            throw CancellationError()
        }
    }

    func complete(with result: Result<Void, LearningProjectError>) {
        behavior = .result(result)

        switch result {
        case .success:
            pendingContinuation?.yield(())
            pendingContinuation?.finish()

        case .failure(let error):
            pendingContinuation?.finish(throwing: error)
        }
    }

    func snapshot() -> [String] {
        projectIDs
    }

    // MARK: Private

    private var behavior: Behavior
    private var projectIDs = [String]()
    private let pendingStream: AsyncThrowingStream<Void, Error>?
    private let pendingContinuation: AsyncThrowingStream<Void, Error>.Continuation?

}
