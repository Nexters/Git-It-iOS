import DomainUseCaseInterface
import Synchronization

struct ExternalRepositoryUseCaseFixedResultStub: ExternalRepositoryUseCase {

    // MARK: Lifecycle

    init(result: Result<ExternalRepository, any Error>) {
        self.result = ResultBox(result)
    }

    // MARK: Internal

    func repository(at _: ExternalRepositoryURL) async throws -> ExternalRepository {
        try result.resolve()
    }

    // MARK: Private

    private final class ResultBox: Sendable {

        // MARK: Lifecycle

        init(_ value: Result<ExternalRepository, any Error>) {
            storage = Mutex(value)
        }

        // MARK: Internal

        func resolve() throws -> ExternalRepository {
            try storage.withLock { try $0.get() }
        }

        // MARK: Private

        private let storage: Mutex<Result<ExternalRepository, any Error>>

    }

    private let result: ResultBox

}
