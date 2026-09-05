import DomainLearningProject
import Foundation
import Synchronization

// MARK: - StubRepositoryURLParser

/// 로컬 판정 결과를 고정한다. 네트워크를 사용하지 않는다.
struct StubRepositoryURLParser: ExternalRepositoryURLParser {

    // MARK: Lifecycle

    init(location: ExternalRepositoryLocation?) {
        self.location = location
    }

    // MARK: Internal

    func location(from url: String) -> ExternalRepositoryLocation? {
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

    func callAsFunction(url: String) async throws -> ExternalRepository {
        try result.value.get()
    }

    // MARK: Private

    private struct ResultBox: @unchecked Sendable {

        init(_ value: Result<ExternalRepository, any Error>) {
            self.value = value
        }

        let value: Result<ExternalRepository, any Error>

    }

    private let result: ResultBox

}

// MARK: - SpyCreateLearningProject

/// 등록 호출 횟수와 전달된 난이도를 기록한다.
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

    /// 진행 중 상태를 유지하려고 멈춰 둔 호출을 끝낸다.
    func resume() {
        gate.continuation.finish()
    }

    func callAsFunction(
        githubRepoURL: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        calls.withLock { state in
            state.count += 1
            state.last = quizLevel
        }
        if suspendsUntilResumed {
            for await _ in gate.stream { }
        }
        if let error { throw error }
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
