import DataLearningProject
import DomainLearningProject

// MARK: - LearningProjectRepositoryAdapter

struct LearningProjectRepositoryAdapter: LearningProjectRepository {

    // MARK: Lifecycle

    init(remote: ProjectRemote) {
        self.remote = remote
    }

    // MARK: Internal

    func register(
        githubRepoURL: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        do {
            let response = try await remote.registerProject(
                RegisterProjectRequestDTO(githubRepoURL: githubRepoURL, quizLevel: dtoQuizLevel(quizLevel))
            )
            return ProjectRegistrationReceipt(
                projectID: response.projectID,
                requestStatus: response.requestStatus,
                quizLevel: quizLevel,
            )
        } catch let error as DataLearningProjectError {
            throw domainError(for: error)
        }
    }

    func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> LearningProjectPage {
        do {
            let response = try await remote.fetchProjects(page: page, size: size)
            return LearningProjectPage(
                items: response.items.map(summary(from:)),
                hasNext: response.hasNext,
            )
        } catch let error as DataLearningProjectError {
            throw domainError(for: error)
        }
    }

    func fetchProjectDetail(projectID: String) async throws -> LearningProjectDetail {
        do {
            let response = try await remote.fetchProjectDetail(projectID: projectID)
            return LearningProjectDetail(
                projectID: response.projectID,
                repositoryURL: response.repositoryURL,
                repositoryName: response.repositoryName,
                repositoryImageURL: response.repositoryImageURL,
                starCount: response.starCount,
                techStack: response.techStack,
                overallProgressPercent: response.overallProgressPercent,
                nextQuestionID: response.nextQuestionID,
                sets: response.sets.map {
                    LearningProjectSetProgress(
                        setID: $0.setID,
                        label: $0.label,
                        title: $0.title,
                        problemCount: 0,
                        completedCount: 0,
                    )
                },
            )
        } catch let error as DataLearningProjectError {
            throw domainError(for: error)
        }
    }

    func deleteProject(projectID: String) async throws {
        do {
            try await remote.deleteProject(projectID: projectID)
        } catch let error as DataLearningProjectError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: ProjectRemote

    private func summary(from dto: ProjectListItemDTO) -> LearningProjectSummary {
        LearningProjectSummary(
            projectID: dto.projectID,
            repositoryName: dto.repositoryName,
            repositoryImageURL: dto.repositoryImageURL,
            techStack: dto.techStack,
            currentSetLabel: dto.currentSetLabel,
            currentSetTitle: dto.currentSetTitle,
            nextSetID: dto.nextSetID,
            nextQuestionID: dto.nextQuestionID,
            overallProgressPercent: dto.overallProgressPercent,
        )
    }

    private func dtoQuizLevel(_ level: QuizLevel) -> QuizLevelDTO {
        switch level {
        case .l1: .l1
        case .l2: .l2
        case .l3: .l3
        @unknown default: .l1
        }
    }

    private func domainError(for error: DataLearningProjectError) -> LearningProjectError {
        switch error {
        case .invalidRequest:
            .invalidRequest

        case .unauthorized:
            .unauthorized

        case .projectUnavailable:
            .notFound

        case .questionUnavailable:
            .questionUnavailable

        case .learningSetUnavailable:
            .learningSetUnavailable

        case .temporarilyUnavailable,
             .transport:
            .temporarilyUnavailable

        case .decoding,
             .unexpectedStatus,
             .generationRetryUnavailable:
            .unexpected

        @unknown default:
            .unexpected
        }
    }

}
