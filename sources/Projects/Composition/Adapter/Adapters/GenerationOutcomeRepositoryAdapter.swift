import DataLearningProject
import DomainLearningProject

// MARK: - GenerationOutcomeRepositoryAdapter

struct GenerationOutcomeRepositoryAdapter: GenerationOutcomeRepository {

    // MARK: Lifecycle

    init(source: any QuizGenerationOutcomeSource) {
        self.source = source
    }

    // MARK: Internal

    func outcomes() async -> AsyncStream<GenerationOutcome> {
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

    // MARK: Private

    private let source: any QuizGenerationOutcomeSource

    private func outcome(from dto: QuizGenerationOutcomeDTO) -> GenerationOutcome {
        switch dto.status {
        case .completed:
            GenerationOutcome(projectID: dto.projectID, status: .completed)

        case .failed:
            GenerationOutcome(projectID: dto.projectID, status: .failed)
        }
    }

}
