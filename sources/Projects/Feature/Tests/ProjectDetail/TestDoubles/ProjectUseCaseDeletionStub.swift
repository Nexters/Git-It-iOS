import DomainUseCaseInterface

actor ProjectUseCaseDeletionStub {

    // MARK: Lifecycle

    init(
        results: [Result<Void, ProjectError>] = [.success(())],
        suspendsRequests: Bool = false,
    ) {
        self.results = results
        self.suspendsRequests = suspendsRequests
    }

    // MARK: Internal

    private(set) var callCount = 0
    private(set) var requestedProjectIDs = [ProjectID]()

    nonisolated var deleteProject: @Sendable (ProjectID) async throws -> Void {
        { try await self(projectID: $0) }
    }

    func callAsFunction(projectID: ProjectID) async throws {
        callCount += 1
        requestedProjectIDs.append(projectID)
        let result = nextResult()
        guard suspendsRequests else { return try result.get() }

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append((continuation, result))
        }
    }

    func resumeOldest() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(with: result)
    }

    // MARK: Private

    private var results: [Result<Void, ProjectError>]
    private let suspendsRequests: Bool
    private var continuations = [(CheckedContinuation<Void, any Error>, Result<Void, ProjectError>)]()

    private func nextResult() -> Result<Void, ProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
