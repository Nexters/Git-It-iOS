@testable import DataLearningProject

// MARK: - LearningProjectRemoteProbe

actor LearningProjectRemoteProbe: ProjectRemote, QuizGenerationRemote, LearningSetRemote, AnswerRemote, BookmarkRemote {

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case registerProject
        case fetchProjects
        case fetchProjectDetail
        case deleteProject
        case fetchGenerationStatus
        case retryQuizGeneration
        case fetchLearningSet
        case submitChoiceAnswer
        case submitEssayAnswer
        case setBookmark
        case fetchBookmarks
    }

    func registerProject(_: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO {
        calls.append(.registerProject)
        return RegisterProjectResponseDTO(projectID: "project-1", status: "IN_PROGRESS")
    }

    func fetchProjects(
        page _: Int,
        size _: Int,
    ) async throws -> ProjectListResponseDTO {
        calls.append(.fetchProjects)
        return ProjectListResponseDTO(
            items: [
                ProjectListItemDTO(
                    projectID: "project-1",
                    repositoryName: "repo",
                    repositoryImageURL: nil,
                    techStack: ["Swift"],
                    currentSetLabel: "Set 1",
                    currentSetTitle: "Basics",
                    nextSetID: nil,
                    nextQuestionID: nil,
                    overallProgressPercent: 0,
                )
            ],
            hasNext: false,
        )
    }

    func fetchProjectDetail(projectID _: String) async throws -> ProjectDetailResponseDTO {
        calls.append(.fetchProjectDetail)
        return ProjectDetailResponseDTO(
            projectID: "project-1",
            repositoryURL: "https://github.com/example/repo",
            repositoryName: "repo",
            repositoryImageURL: nil,
            starCount: 0,
            techStack: ["Swift"],
            overallProgressPercent: 0,
            nextQuestionID: nil,
            sets: [],
        )
    }

    func deleteProject(projectID _: String) async throws {
        calls.append(.deleteProject)
    }

    func fetchGenerationStatus(projectID _: String) async throws -> QuizGenerationStatusResponseDTO {
        calls.append(.fetchGenerationStatus)
        return QuizGenerationStatusResponseDTO(status: "COMPLETED")
    }

    func retryQuizGeneration(projectID _: String) async throws {
        calls.append(.retryQuizGeneration)
    }

    func fetchLearningSet(
        projectID _: String,
        setID _: String,
    ) async throws -> LearningSetResponseDTO {
        calls.append(.fetchLearningSet)
        return LearningSetResponseDTO(
            setID: "set-1",
            title: "Basics",
            description: "",
            orientation: "horizontal",
            level: "L1",
            questions: [],
        )
    }

    func submitChoiceAnswer(
        projectID _: String,
        questionID _: String,
        request _: SubmitChoiceAnswerRequestDTO,
    ) async throws -> SubmitChoiceAnswerResponseDTO {
        calls.append(.submitChoiceAnswer)
        return SubmitChoiceAnswerResponseDTO(questionID: "question-1", correct: true, answerIndex: 0, explanation: "")
    }

    func submitEssayAnswer(
        projectID _: String,
        questionID _: String,
        request _: SubmitEssayAnswerRequestDTO,
    ) async throws -> SubmitEssayAnswerResponseDTO {
        calls.append(.submitEssayAnswer)
        return SubmitEssayAnswerResponseDTO(
            questionID: "question-1",
            explanation: "",
            rubric: RubricResponseDTO(score: 0, feedback: ""),
        )
    }

    func setBookmark(
        projectID _: String,
        questionID _: String,
        request: BookmarkQuestionRequestDTO,
    ) async throws -> BookmarkQuestionResponseDTO {
        calls.append(.setBookmark)
        return BookmarkQuestionResponseDTO(bookmarked: request.bookmarked)
    }

    func fetchBookmarks(projectID _: String?) async throws -> BookmarkedQuestionListResponseDTO {
        calls.append(.fetchBookmarks)
        return BookmarkedQuestionListResponseDTO(totalCount: 0, availableProjects: [], bookmarks: [])
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private var calls = [Call]()

}
