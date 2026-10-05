import DataLearningProject
import DataNotification
import DomainUseCaseDependency
import DomainUseCaseInterface

// MARK: - GenerationOutcomeRepositoryAdapter

public struct GenerationOutcomeRepositoryAdapter: GenerationOutcomeRepository {

    // MARK: Lifecycle

    public init(
        source: any QuizGenerationOutcomeSource,
        deliveredMessages: any DeliveredRemoteMessageReader,
    ) {
        self.source = source
        self.deliveredMessages = deliveredMessages
    }

    // MARK: Public

    public func outcomes() async -> AsyncStream<GenerationOutcome> {
        let dtoStream = source.outcomes()
        return AsyncStream { continuation in
            let task = Task {
                for await dto in dtoStream {
                    continuation.yield(outcome(from: dto))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func deliveredOutcomes() async -> [GenerationOutcome] {
        await deliveredMessages.deliveredMessages().compactMap { message in
            QuizGenerationOutcomeDTO(
                rawPayload: message.payload,
                deliveredAt: message.deliveredAt,
            ).map(outcome(from:))
        }
    }

    // MARK: Private

    private let source: any QuizGenerationOutcomeSource
    private let deliveredMessages: any DeliveredRemoteMessageReader

    private func outcome(from dto: QuizGenerationOutcomeDTO) -> GenerationOutcome {
        switch dto.status {
        case .completed:
            GenerationOutcome(
                projectID: dto.projectID,
                status: .completed,
                arrivedAt: dto.deliveredAt,
            )

        case .failed:
            GenerationOutcome(
                projectID: dto.projectID,
                status: .failed,
                arrivedAt: dto.deliveredAt,
            )
        }
    }

}
