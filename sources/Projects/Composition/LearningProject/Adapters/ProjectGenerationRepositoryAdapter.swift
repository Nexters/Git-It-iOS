import DataLearningProject
import DomainUseCaseDependency
import DomainUseCaseInterface

// MARK: - ProjectGenerationRepositoryAdapter

public struct ProjectGenerationRepositoryAdapter: ProjectGenerationRepository {

    // MARK: Lifecycle

    public init(remote: ProjectRemote) {
        self.remote = remote
    }

    // MARK: Public

    public func register(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt {
        do {
            let response = try await remote.registerProject(RegisterProjectRequestDTO(
                githubRepoURL: request.repositoryURL,
                quizLevel: dtoQuizLevel(request.quizLevel),
            ))
            return ProjectGenerationReceipt(
                projectID: response.projectID,
                quizLevel: request.quizLevel,
            )
        } catch let error as LearningProjectServiceError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: ProjectRemote

    private func dtoQuizLevel(_ level: QuizLevel) -> QuizLevelDTO {
        switch level {
        case .l1: .l1
        case .l2: .l2
        case .l3: .l3
        @unknown default: .l1
        }
    }

    private func domainError(for error: LearningProjectServiceError) -> ProjectGenerationError {
        switch error {
        case .invalidRequest:
            .invalidRequest

        case .unauthorized:
            .unauthorized

        case .projectUnavailable,
             .questionUnavailable,
             .learningSetUnavailable,
             .temporarilyUnavailable,
             .transport:
            .temporarilyUnavailable

        case .unexpectedStatus:
            .unexpected

        @unknown default:
            .unexpected
        }
    }

}
