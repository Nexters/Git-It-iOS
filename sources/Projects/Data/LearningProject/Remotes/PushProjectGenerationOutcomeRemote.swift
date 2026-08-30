import Foundation

// MARK: - PushProjectGenerationOutcomeRemote

public actor PushProjectGenerationOutcomeRemote: ProjectGenerationOutcomeRemote {

    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func outcomes() -> AsyncStream<ProjectGenerationOutcomeDTO> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id: id) }
            }
        }
    }

    public func ingest(rawPayload: [String: String]) async {
        guard let outcome = ProjectGenerationOutcomeDTO(rawPayload: rawPayload) else { return }
        for continuation in continuations.values {
            continuation.yield(outcome)
        }
    }

    // MARK: Private

    private var continuations: [UUID: AsyncStream<ProjectGenerationOutcomeDTO>.Continuation] = [:]

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }

}
