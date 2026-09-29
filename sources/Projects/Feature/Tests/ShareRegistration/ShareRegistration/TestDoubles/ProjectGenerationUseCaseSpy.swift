import DomainIdentifier
import DomainProjectGeneration
import Synchronization

final class ProjectGenerationUseCaseSpy: ProjectGenerationUseCase, Sendable {

    // MARK: Lifecycle

    init(
        projectID: ProjectID = "project-1",
        error: ProjectGenerationError? = nil,
        suspendsUntilResumed: Bool = false,
        currentStates: [Result<ProjectGenerationState, ProjectGenerationError>] = [
            .success(ProjectGenerationState(requests: []))
        ],
    ) {
        self.projectID = projectID
        self.error = error
        self.suspendsUntilResumed = suspendsUntilResumed
        stateReads = Mutex(StateReads(results: currentStates))
    }

    // MARK: Internal

    var callCount: Int {
        calls.withLock { $0.count }
    }

    var lastQuizLevel: QuizLevel? {
        calls.withLock { $0.last }
    }

    var currentStateCallCount: Int {
        stateReads.withLock { $0.count }
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
        return ProjectGenerationReceipt(
            projectID: projectID,
            quizLevel: request.quizLevel,
        )
    }

    func states() async -> AsyncStream<ProjectGenerationState> {
        AsyncStream { $0.finish() }
    }

    func currentState() async throws(ProjectGenerationError) -> ProjectGenerationState {
        let result = stateReads.withLock { reads -> Result<ProjectGenerationState, ProjectGenerationError> in
            reads.count += 1
            guard let last = reads.results.last else { return .success(ProjectGenerationState(requests: [])) }
            let index = reads.count - 1
            return index < reads.results.count ? reads.results[index] : last
        }
        return try result.get()
    }

    func outcomeArrivals() async -> AsyncStream<ProjectID> {
        AsyncStream { $0.finish() }
    }

    func synchronize() async { }

    func release(_: ProjectID) async { }

    // MARK: Private

    private struct Calls {
        var count = 0
        var last: QuizLevel?
    }

    private struct StateReads {
        let results: [Result<ProjectGenerationState, ProjectGenerationError>]
        var count = 0
    }

    private let projectID: ProjectID
    private let error: ProjectGenerationError?
    private let suspendsUntilResumed: Bool
    private let gate = AsyncStream.makeStream(of: Void.self)
    private let calls = Mutex(Calls())
    private let stateReads: Mutex<StateReads>

}
