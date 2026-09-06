import DomainLearningProject
import Foundation
import Synchronization

// MARK: - StubRepositoryURLParser

struct StubRepositoryURLParser: ExternalRepositoryURLParser {

    // MARK: Lifecycle

    init(location: ExternalRepositoryLocation?) {
        self.location = location
    }

    // MARK: Internal

    func location(from _: String) -> ExternalRepositoryLocation? {
        location
    }

    // MARK: Private

    private let location: ExternalRepositoryLocation?

}

// MARK: - StubFetchExternalRepository

struct StubFetchExternalRepository: FetchExternalRepositoryUseCase {

    // MARK: Lifecycle

    init(result: Result<ExternalRepository, any Error>) {
        self.result = ResultBox(result)
    }

    // MARK: Internal

    func callAsFunction(url _: String) async throws -> ExternalRepository {
        try result.resolve()
    }

    // MARK: Private

    private struct ResultBox: Sendable {

        init(_ value: Result<ExternalRepository, any Error>) {
            storage = Mutex(value)
        }

        func resolve() throws -> ExternalRepository {
            try storage.withLock { try $0.get() }
        }

        private let storage: Mutex<Result<ExternalRepository, any Error>>

    }

    private let result: ResultBox

}

// MARK: - SpyCreateLearningProject

final class SpyCreateLearningProject: CreateLearningProjectUseCase, Sendable {

    // MARK: Lifecycle

    init(
        projectID: String = "project-1",
        error: LearningProjectError? = nil,
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

    func callAsFunction(
        githubRepoURL _: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        calls.withLock { state in
            state.count += 1
            state.last = quizLevel
        }
        if suspendsUntilResumed {
            for await _ in gate.stream { }
        }
        if let error {
            throw error
        }
        return ProjectRegistrationReceipt(
            projectID: projectID,
            requestStatus: "accepted",
            quizLevel: quizLevel,
        )
    }

    // MARK: Private

    private struct Calls {
        var count = 0
        var last: QuizLevel?
    }

    private let projectID: String
    private let error: LearningProjectError?
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
