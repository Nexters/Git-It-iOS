import DataLearningProject
import DomainLearningProject

// MARK: - GenerationOutcomeRepositoryAdapter

struct GenerationOutcomeRepositoryAdapter: GenerationOutcomeRepository {

    // MARK: Lifecycle

    init(remote: any GenerationOutcomeStream) {
        self.remote = remote
    }

    // MARK: Internal

    func outcomes() async -> AsyncStream<GenerationOutcome> {
        let dtoStream = remote.outcomes()
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

    private let remote: any GenerationOutcomeStream

    private func outcome(from dto: GenerationOutcomeDTO) -> GenerationOutcome {
        switch dto.status {
        case .completed:
            GenerationOutcome(projectID: dto.projectID, status: .completed)

        case .failed:
            GenerationOutcome(projectID: dto.projectID, status: .failed)
        }
    }

}
