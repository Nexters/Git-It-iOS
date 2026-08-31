import Foundation
import Synchronization

// MARK: - PushProjectGenerationOutcomeRemote

public final class PushProjectGenerationOutcomeRemote: ProjectGenerationOutcomeRemote, Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func outcomes() -> AsyncStream<ProjectGenerationOutcomeDTO> {
        let id = UUID()
        return AsyncStream { continuation in
            state.withLock { $0.continuations[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { _ = $0.continuations.removeValue(forKey: id) }
            }
        }
    }

    public func ingest(rawPayload: [String: String]) async {
        guard let outcome = ProjectGenerationOutcomeDTO(rawPayload: rawPayload) else { return }
        let continuations = state.withLock { Array($0.continuations.values) }
        for continuation in continuations {
            continuation.yield(outcome)
        }
    }

    // MARK: Private

    private struct State {
        var continuations = [UUID: AsyncStream<ProjectGenerationOutcomeDTO>.Continuation]()
    }

    private let state = Mutex(State())

}
