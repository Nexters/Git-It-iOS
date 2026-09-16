import DataLearningProject
import DomainLearningProject
import Foundation

// MARK: - GenerationStateRepositoryAdapter

struct GenerationStateRepositoryAdapter: GenerationStateRepository {

    // MARK: Lifecycle

    init(store: any GenerationStateStore) {
        self.store = store
    }

    // MARK: Internal

    func load() async -> GenerationState {
        GenerationState(records: await store.load().records.compactMap(record(from:)))
    }

    func save(_ state: GenerationState) async {
        await store.save(GenerationStateDTO(records: state.records.map(dto(from:))))
    }

    // MARK: Private

    private static let inProgressStatus = "inProgress"
    private static let completedStatus = "completed"
    private static let failedStatus = "failed"

    private let store: any GenerationStateStore

    private func record(from dto: GenerationRecordDTO) -> GenerationRecord? {
        guard let status = status(from: dto.status) else { return nil }
        return GenerationRecord(
            githubRepoURL: dto.githubRepoURL,
            projectID: dto.projectID,
            requestedAt: dto.requestedAt,
            status: status,
            finishedAt: dto.finishedAt,
        )
    }

    private func status(from rawValue: String) -> GenerationRecord.Status? {
        switch rawValue {
        case Self.inProgressStatus:
            .inProgress

        case Self.completedStatus:
            .completed

        case Self.failedStatus:
            .failed

        default:
            nil
        }
    }

    private func dto(from record: GenerationRecord) -> GenerationRecordDTO {
        GenerationRecordDTO(
            githubRepoURL: record.githubRepoURL,
            projectID: record.projectID,
            requestedAt: record.requestedAt,
            status: rawValue(from: record.status),
            finishedAt: record.finishedAt,
        )
    }

    private func rawValue(from status: GenerationRecord.Status) -> String {
        switch status {
        case .inProgress:
            Self.inProgressStatus

        case .completed:
            Self.completedStatus

        case .failed:
            Self.failedStatus
        }
    }

}
