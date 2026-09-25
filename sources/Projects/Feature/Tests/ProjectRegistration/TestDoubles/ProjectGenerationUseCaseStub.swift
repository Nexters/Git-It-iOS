import DomainIdentifier
import DomainProjectGeneration

actor ProjectGenerationUseCaseStub: ProjectGenerationUseCase {

    // MARK: Lifecycle

    init(
        results: [Result<ProjectGenerationReceipt, ProjectGenerationError>] = [.failure(.unexpected)],
        generationStates: ProjectGenerationStateStreamStub = ProjectGenerationStateStreamStub(),
        suspendsRequests: Bool = false,
    ) {
        self.results = results
        self.generationStates = generationStates
        self.suspendsRequests = suspendsRequests
    }

    // MARK: Internal

    func request(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt {
        requests.append(request)
        let result = nextResult()
        guard suspendsRequests else { return try result.get() }

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append((continuation, result))
        }
    }

    func states() async -> AsyncStream<ProjectGenerationState> {
        await generationStates.states()
    }

    func synchronize() async { }

    func release(_: ProjectID) async { }

    func recordedRequests() -> [ProjectGenerationRequest] {
        requests
    }

    func resumeOldest() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(with: result)
    }

    // MARK: Private

    private var results: [Result<ProjectGenerationReceipt, ProjectGenerationError>]
    private let generationStates: ProjectGenerationStateStreamStub
    private let suspendsRequests: Bool
    private var requests = [ProjectGenerationRequest]()
    private var continuations = [(
        CheckedContinuation<ProjectGenerationReceipt, any Error>,
        Result<ProjectGenerationReceipt, ProjectGenerationError>,
    )]()

    private func nextResult() -> Result<ProjectGenerationReceipt, ProjectGenerationError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
