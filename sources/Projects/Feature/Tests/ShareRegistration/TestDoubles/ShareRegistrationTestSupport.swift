import DomainExternalRepository
import DomainIdentifier
import DomainProjectGeneration
import Foundation
import Synchronization

// MARK: - StubRepositoryURLParser

struct StubRepositoryURLParser: ExternalRepositoryLocator {

    // MARK: Lifecycle

    init(location: ExternalRepositoryLocation?) {
        self.location = location
    }

    // MARK: Internal

    func location(from _: ExternalRepositoryURL) -> ExternalRepositoryLocation? {
        location
    }

    // MARK: Private

    private let location: ExternalRepositoryLocation?

}

// MARK: - StubFetchExternalRepository

struct StubFetchExternalRepository: ExternalRepositoryUseCase {

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

// MARK: - SpyCreateLearningProject

final class SpyCreateLearningProject: ProjectGenerationUseCase, Sendable {

    // MARK: Lifecycle

    init(
        projectID: ProjectID = "project-1",
        error: ProjectGenerationError? = nil,
        suspendsUntilResumed: Bool = false,
    ) {
        self.projectID = projectID
        self.error = error
        self.suspendsUntilResumed = suspendsUntilResumed
    }

    // MARK: Internal

    var callCount: Int {
        calls.withLock { $0.count }
    }

    var lastQuizLevel: QuizLevel? {
        calls.withLock { $0.last }
    }

    func resume() {
        gate.continuation.finish()
    }

    func request(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt {
        calls.withLock { state in
            state.count += 1
            state.last = request.quizLevel
        }
        if suspendsUntilResumed {
            for await _ in gate.stream { }
        }
        if let error {
            throw error
        }
        return ProjectGenerationReceipt(projectID: projectID, quizLevel: request.quizLevel)
    }

    func states() async -> AsyncStream<ProjectGenerationState> {
        AsyncStream { $0.finish() }
    }

    // MARK: Private

    private struct Calls {
        var count = 0
        var last: QuizLevel?
    }

    private let projectID: ProjectID
    private let error: ProjectGenerationError?
    private let suspendsUntilResumed: Bool
    private let gate = AsyncStream.makeStream(of: Void.self)
    private let calls = Mutex(Calls())

}

// MARK: - ShareRegistrationTestSupport

enum ShareRegistrationTestSupport {

    static let sharedURL = "https://github.com/apple/swift"

    static let location = ExternalRepositoryLocation(owner: "apple", name: "swift")

    static let repository = ExternalRepository(
        canonicalURL: "https://github.com/apple/swift",
        ownerName: "apple",
        repositoryName: "swift",
        imageURL: nil,
        starCount: 1000,
        techStack: ["Swift"],
    )

}
