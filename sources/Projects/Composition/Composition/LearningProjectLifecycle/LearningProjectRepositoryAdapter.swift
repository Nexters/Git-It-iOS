import DataLearningProject
import DomainLearningProject

public struct LearningProjectRepositoryAdapter: LearningProjectRepository {

    // MARK: Lifecycle

    public init(remote: LearningProjectRemote) {
        self.remote = remote
    }

    // MARK: Public

    public func register(
        githubRepoUrl: String,
        quizLevel: QuizLevel,
    ) async throws -> LearningProjectRegistration {
        do {
            let dto = try await remote.registerProject(
                RegisterProjectRequestDTO(
                    githubRepoUrl: githubRepoUrl,
                    quizLevel: dataQuizLevel(from: quizLevel),
                )
            )
            return LearningProjectRegistration(
                projectId: dto.projectId,
                status: domainStatus(from: dto.status),
                quizLevel: quizLevel,
            )
        } catch {
            throw mappedError(error)
        }
    }

    public func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> LearningProjectPage {
        do {
            let dto = try await remote.fetchProjects(page: page, size: size)
            return LearningProjectPage(
                items: dto.items.map(summary(from:)),
                hasNext: dto.hasNext,
            )
        } catch {
            throw mappedError(error)
        }
    }

    public func fetchProjectDetail(projectId: String) async throws -> LearningProjectDetail {
        do {
            let dto = try await remote.fetchProjectDetail(projectId: projectId)
            return LearningProjectDetail(
                projectId: dto.projectId,
                repositoryURL: dto.repositoryUrl,
                repositoryName: dto.repositoryName,
                repositoryImageURL: dto.repositoryImageUrl,
                starCount: dto.starCount,
                techStack: dto.techStack,
                overallProgressPercent: dto.overallProgressPercent,
                nextQuestionId: dto.nextQuestionId,
                sets: dto.sets.map(setProgress(from:)),
            )
        } catch {
            throw mappedError(error)
        }
    }

    public func deleteProject(projectId: String) async throws {
        do {
            try await remote.deleteProject(projectId: projectId)
        } catch {
            throw mappedError(error)
        }
    }

    // MARK: Private

    private let remote: LearningProjectRemote

    private func summary(from dto: ProjectListItemDTO) -> LearningProjectSummary {
        LearningProjectSummary(
            projectId: dto.projectId,
            repositoryName: dto.repositoryName,
            repositoryImageURL: dto.repositoryImageUrl,
            techStack: dto.techStack,
            currentSetLabel: dto.currentSetLabel,
            currentSetTitle: dto.currentSetTitle,
            nextSetId: dto.nextSetId,
            nextQuestionId: dto.nextQuestionId,
            overallProgressPercent: dto.overallProgressPercent,
        )
    }

    private func setProgress(from dto: ProjectSetSummaryDTO) -> LearningProjectSetProgress {
        LearningProjectSetProgress(
            setId: dto.setId,
            label: dto.label,
            title: dto.title,
            problemCount: dto.problemCount,
            completedCount: dto.completedCount,
        )
    }

    private func dataQuizLevel(from quizLevel: QuizLevel) -> QuizLevelDTO {
        switch quizLevel {
        case .l1: .l1
        case .l2: .l2
        case .l3: .l3
        }
    }

    private func domainStatus(from status: QuizGenerationStatusDTO) -> QuizGenerationStatus {
        switch status {
        case .ready: .ready
        case .analyzed: .analyzed
        case .anchored: .anchored
        case .rejected: .rejected
        case .failed: .failed
        case .completed: .completed
        }
    }

    private func mappedError(_ error: Error) -> LearningProjectError {
        guard let dataError = error as? DataLearningProjectError
        else {
            return .unexpected
        }

        return switch dataError {
        case .invalidRequest: .invalidRequest
        case .unauthorized: .unauthorized
        case .notFound: .notFound
        case .serverError,
             .unexpected: .unexpected
        }
    }

}
