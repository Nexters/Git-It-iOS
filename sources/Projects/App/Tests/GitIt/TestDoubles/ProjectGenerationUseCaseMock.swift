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

    func emit(_ next: ProjectGenerationState) {
        state = next
        continuation?.yield(state)
    }

    func finish() {
        continuation?.finish()
    }

    // MARK: Private

    private let keepsObservationOpen: Bool
    private var state: ProjectGenerationState
    private var continuation: AsyncStream<ProjectGenerationState>.Continuation?

}
