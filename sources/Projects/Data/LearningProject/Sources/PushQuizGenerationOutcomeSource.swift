import Foundation
import os
import Synchronization

// MARK: - PushQuizGenerationOutcomeSource

public final class PushQuizGenerationOutcomeSource: QuizGenerationOutcomeSource, Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func outcomes() -> AsyncStream<QuizGenerationOutcomeDTO> {
        let subscriptionID = UUID()
        return AsyncStream { continuation in
            state.withLock { $0.continuations[subscriptionID] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { _ = $0.continuations.removeValue(forKey: subscriptionID) }
            }
        }
    }

    public func ingest(rawPayload: [String: String]) async {
        guard let outcome = QuizGenerationOutcomeDTO(rawPayload: rawPayload) else {
            Self.logger.debug("생성 결과 payload 파싱 실패: rawPayload=\(rawPayload, privacy: .public)")
            return
        }
        Self.logger
            .debug(
                "생성 결과 payload 파싱 성공: projectID=\(outcome.projectID, privacy: .public) status=\(String(describing: outcome.status), privacy: .public)"
            )
        let continuations = state.withLock { Array($0.continuations.values) }
        for continuation in continuations {
            continuation.yield(outcome)
        }
    }

    // MARK: Private

    private struct State {
        var continuations = [UUID: AsyncStream<QuizGenerationOutcomeDTO>.Continuation]()
    }

    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "PushQuizGenerationOutcomeSource")

    private let state = Mutex(State())

}
