import Foundation
import os
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
        guard let outcome = ProjectGenerationOutcomeDTO(rawPayload: rawPayload) else {
            Self.logger.debug("생성 결과 payload 파싱 실패: rawPayload=\(rawPayload, privacy: .public)")
            return
        }
        Self.logger.debug("생성 결과 payload 파싱 성공: projectID=\(outcome.projectID, privacy: .public) status=\(String(describing: outcome.status), privacy: .public)")
        let continuations = state.withLock { Array($0.continuations.values) }
        for continuation in continuations {
            continuation.yield(outcome)
        }
    }

    // MARK: Private

    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "PushProjectGenerationOutcomeRemote")

    private struct State {
        var continuations = [UUID: AsyncStream<ProjectGenerationOutcomeDTO>.Continuation]()
    }

    private let state = Mutex(State())

}
