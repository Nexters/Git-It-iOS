import Foundation
import os
import Synchronization

// MARK: - PushQuizGenerationOutcomeSource

public final class PushQuizGenerationOutcomeSource: QuizGenerationOutcomeSource, Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public static let pendingOutcomeLimit = 32

    public func outcomes() -> AsyncStream<QuizGenerationOutcomeDTO> {
        let subscriptionID = UUID()
        return AsyncStream { continuation in
            let pendingOutcomes = state.withLock { state -> [QuizGenerationOutcomeDTO] in
                state.continuations[subscriptionID] = continuation
                let pendingOutcomes = state.pendingOutcomes
                state.pendingOutcomes = []
                return pendingOutcomes
            }
            if !pendingOutcomes.isEmpty {
                Self.logger.debug("보존한 생성 결과 \(pendingOutcomes.count, privacy: .public)개를 첫 구독자에게 전달합니다.")
            }
            for outcome in pendingOutcomes {
                continuation.yield(outcome)
            }
            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { _ = $0.continuations.removeValue(forKey: subscriptionID) }
            }
        }
    }

    public func ingest(
        rawPayload: [String: String],
        deliveredAt: Date,
    ) async {
        guard
            let outcome = QuizGenerationOutcomeDTO(
                rawPayload: rawPayload,
                deliveredAt: deliveredAt,
            )
        else {
            Self.logger.debug("생성 결과 payload 파싱 실패: rawPayload=\(rawPayload, privacy: .public)")
            return
        }
        Self.logger
            .debug(
                "생성 결과 payload 파싱 성공: projectID=\(outcome.projectID, privacy: .public) status=\(String(describing: outcome.status), privacy: .public) deliveredAt=\(outcome.deliveredAt, privacy: .public)"
            )
        let continuations = state.withLock { state -> [AsyncStream<QuizGenerationOutcomeDTO>.Continuation] in
            guard state.continuations.isEmpty else { return Array(state.continuations.values) }
            state.pendingOutcomes.append(outcome)
            if state.pendingOutcomes.count > Self.pendingOutcomeLimit {
                state.pendingOutcomes.removeFirst(state.pendingOutcomes.count - Self.pendingOutcomeLimit)
            }
            return []
        }
        guard !continuations.isEmpty else {
            Self.logger.debug("구독자가 없어 생성 결과를 보존합니다: projectID=\(outcome.projectID, privacy: .public)")
            return
        }
        for continuation in continuations {
            continuation.yield(outcome)
        }
    }

    // MARK: Private

    private struct State {
        var continuations = [UUID: AsyncStream<QuizGenerationOutcomeDTO>.Continuation]()
        var pendingOutcomes = [QuizGenerationOutcomeDTO]()
    }

    private static let logger = Logger(
        subsystem: "com.nexters.hytime.gitit",
        category: "PushQuizGenerationOutcomeSource",
    )

    private let state = Mutex(State())

}
