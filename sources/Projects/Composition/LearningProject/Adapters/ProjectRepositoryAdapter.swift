import DataLearningProject
import DomainUseCaseDependency
import DomainUseCaseInterface

// MARK: - ProjectRepositoryAdapter

public struct ProjectRepositoryAdapter: ProjectRepository {

    // MARK: Lifecycle

    public init(remote: ProjectRemote) {
        self.remote = remote
    }

    // MARK: Public

    public func page(
        _ index: Int,
        size: Int,
    ) async throws -> ProjectPage {
        do {
            let response = try await remote.fetchProjects(
                page: index,
                size: size,
            )
            return ProjectPage(
                summaries: response.items.map(summary(from:)),
                hasNextPage: response.hasNext,
            )
        } catch let error as LearningProjectServiceError {
            throw domainError(for: error)
        }
    }

    public func detail(of projectID: ProjectID) async throws -> ProjectDetail {
        do {
            let response = try await remote.fetchProjectDetail(projectID: projectID)
            let sets = response.sets.map {
                ProjectSetProgress(
                    setID: $0.setID,
                    label: $0.label,
                    title: $0.title,
                    quizCount: $0.problemCount,
                    completedCount: $0.completedCount,
                )
            }
            return ProjectDetail(
                id: response.projectID,
                repository: ProjectRepositoryInfo(
                    url: response.repositoryURL,
                    name: response.repositoryName,
                    imageURL: response.repositoryImageURL,
                    starCount: response.starCount,
                    techStack: response.techStack,
                ),
                progressPercent: response.overallProgressPercent,
                sets: sets,
                next: next(
                    in: sets,
                    quizID: response.nextQuestionID,
                ),
            )
        } catch let error as LearningProjectServiceError {
            throw domainError(for: error)
        }
    }

    public func delete(_ projectID: ProjectID) async throws {
        do {
            try await remote.deleteProject(projectID: projectID)
        } catch let error as LearningProjectServiceError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: ProjectRemote

    private func summary(from dto: ProjectListItemDTO) -> ProjectSummary {
        ProjectSummary(
            id: dto.projectID,
            repositoryName: dto.repositoryName,
            repositoryImageURL: dto.repositoryImageURL,
            techStack: dto.techStack,
            currentSet: ProjectSetLabel(
                label: dto.currentSetLabel,
                title: dto.currentSetTitle,
            ),
            next: dto.nextSetID.map { ProjectNextQuiz(
                setID: $0,
                quizID: dto.nextQuestionID,
            ) },
            progressPercent: dto.overallProgressPercent,
        )
    }

    private func next(
        in sets: [ProjectSetProgress],
        quizID: QuizID?,
    ) -> ProjectNextQuiz? {
        let incomplete = sets.first { $0.completedCount < $0.quizCount }
        guard let target = incomplete ?? sets.first else { return nil }
        return ProjectNextQuiz(
            setID: target.setID,
            quizID: quizID,
        )
    }

    private func domainError(for error: LearningProjectServiceError) -> ProjectError {
        switch error {
        case .invalidRequest:
            .invalidRequest

        case .unauthorized:
            .unauthorized

        case .projectUnavailable,
             .questionUnavailable,
             .learningSetUnavailable:
            .notFound

        case .temporarilyUnavailable,
             .transport:
            .temporarilyUnavailable

        case .unexpectedStatus:
            .unexpected

        @unknown default:
            .unexpected
        }
    }

}
