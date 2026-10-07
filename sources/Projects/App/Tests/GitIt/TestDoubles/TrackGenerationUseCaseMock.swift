import DomainLearningProject
import Foundation

actor TrackGenerationUseCaseMock: TrackGenerationUseCase {

    // MARK: Lifecycle

    init(
        stored: GenerationState = GenerationState(),
        keepsObservationOpen: Bool = false,
    ) {
        state = stored
        self.keepsObservationOpen = keepsObservationOpen
    }

    // MARK: Internal

    private(set) var endedGithubRepoURLs = [String]()

    func begin(
        githubRepoURL: String,
        requestedAt: Date,
    ) async -> Bool {
        guard let next = state.beginning(githubRepoURL: githubRepoURL, requestedAt: requestedAt) else {
            return false
        }
        state = next
        yieldCurrent()
        return true
    }

    func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async {
        state = state.attachingProjectID(projectID, toGithubRepoURL: githubRepoURL)
        yieldCurrent()
    }

    func end(githubRepoURL: String) async {
        endedGithubRepoURLs.append(githubRepoURL)
        state = state.removing(githubRepoURL: githubRepoURL)
        yieldCurrent()
    }

    func end(projectID: String) async {
        state = state.removing(projectID: projectID)
        yieldCurrent()
    }

    func current() async -> GenerationState {
        state
    }

    func states() async -> AsyncStream<GenerationState> {
        let (stream, continuation) = AsyncStream<GenerationState>.makeStream()
        self.continuation = continuation
        continuation.yield(state)
        if !keepsObservationOpen {
            continuation.finish()
        }
        return stream
    }

    func emit(_ next: GenerationState) {
        state = next
        yieldCurrent()
    }

    func finish() {
        continuation?.finish()
    }

    // MARK: Private

    private let keepsObservationOpen: Bool
    private var state: GenerationState
    private var continuation: AsyncStream<GenerationState>.Continuation?

    private func yieldCurrent() {
        continuation?.yield(state)
    }

}
