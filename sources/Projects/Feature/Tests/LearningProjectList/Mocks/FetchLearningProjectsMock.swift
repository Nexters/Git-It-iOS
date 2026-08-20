import DomainLearningProject

actor FetchLearningProjectsMock: FetchLearningProjectsUseCase {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior

        if case .pending = behavior {
            let pair = AsyncThrowingStream<LearningProjectPage, Error>.makeStream()
            pendingStream = pair.stream
            pendingContinuation = pair.continuation
        } else {
            pendingStream = nil
            pendingContinuation = nil
        }
    }

    // MARK: Internal

    struct Call: Sendable, Equatable {
        let page: Int
        let size: Int
    }

    enum Behavior: Sendable {
        case result(Result<LearningProjectPage, LearningProjectError>)
        case pending
    }

    func callAsFunction(
        page: Int,
        size: Int,
    ) async throws -> LearningProjectPage {
        calls.append(.init(page: page, size: size))

        switch behavior {
        case .result(.success(let page)):
            return page

        case .result(.failure(let error)):
            throw error

        case .pending:
            guard let pendingStream else {
                throw CancellationError()
            }

            for try await page in pendingStream {
                return page
            }
            throw CancellationError()
        }
    }

    func complete(with result: Result<LearningProjectPage, LearningProjectError>) {
        behavior = .result(result)

        switch result {
        case .success(let page):
            pendingContinuation?.yield(page)
            pendingContinuation?.finish()

        case .failure(let error):
            pendingContinuation?.finish(throwing: error)
        }
    }

    func snapshot() -> [Call] {
        calls
    }

    // MARK: Private

    private var behavior: Behavior
    private var calls = [Call]()
    private let pendingStream: AsyncThrowingStream<LearningProjectPage, Error>?
    private let pendingContinuation: AsyncThrowingStream<LearningProjectPage, Error>.Continuation?

}
