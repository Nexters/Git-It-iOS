import DomainIdentifier
import DomainProjectGeneration
import Foundation

actor ProjectGenerationUseCaseMock: ProjectGenerationUseCase {

    // MARK: Lifecycle

    init(
        stored: ProjectGenerationState = ProjectGenerationState(requests: []),
        keepsObservationOpen: Bool = false,
    ) {
        state = stored
        self.keepsObservationOpen = keepsObservationOpen
    }

    // MARK: Internal

    private(set) var requests = [ProjectGenerationRequest]()
    private(set) var synchronizeCount = 0
    private(set) var releasedProjectIDs = [ProjectID]()

    func request(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt {
        requests.append(request)
        throw ProjectGenerationError.temporarilyUnavailable
    }

    func states() async -> AsyncStream<ProjectGenerationState> {
        let (stream, continuation) = AsyncStream<ProjectGenerationState>.makeStream()
        self.continuation = continuation
        continuation.yield(state)
        if !keepsObservationOpen {
            continuation.finish()
        }
        return stream
    }

    func currentState() async throws(ProjectGenerationError) -> ProjectGenerationState {
        state
    }

    func outcomeArrivals() async -> AsyncStream<ProjectID> {
        let (stream, continuation) = AsyncStream<ProjectID>.makeStream()
        arrivalContinuation = continuation
        if !keepsObservationOpen {
            continuation.finish()
        }
        return stream
    }

    func synchronize() async {
        synchronizeCount += 1
    }

    func release(_ projectID: ProjectID) async {
        releasedProjectIDs.append(projectID)
    }

    func emit(_ next: ProjectGenerationState) {
        state = next
        continuation?.yield(state)
    }

    func finish() {
        continuation?.finish()
        arrivalContinuation?.finish()
    }

    func emitArrival(_ projectID: ProjectID) {
        arrivalContinuation?.yield(projectID)
    }

    func finishArrivals() {
        arrivalContinuation?.finish()
    }

    // MARK: Private

    private let keepsObservationOpen: Bool
    private var state: ProjectGenerationState
    private var continuation: AsyncStream<ProjectGenerationState>.Continuation?
    private var arrivalContinuation: AsyncStream<ProjectID>.Continuation?

}
