import DataLearningProject
import DomainIdentifier
import DomainQuizDetail

// MARK: - QuizSetRepositoryAdapter

public struct QuizSetRepositoryAdapter: QuizSetRepository {

    // MARK: Lifecycle

    public init(remote: LearningSetRemote) {
        self.remote = remote
    }

    // MARK: Public

    public func quizSet(
        _ setID: QuizSetID,
        in projectID: ProjectID,
    ) async throws -> QuizSet {
        do {
            let response = try await remote.fetchLearningSet(projectID: projectID, setID: setID)
            return QuizSet(
                id: response.setID,
                title: response.title,
                description: response.description,
                quizzes: response.questions.map(quiz(from:)),
            )
        } catch let error as LearningProjectServiceError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: LearningSetRemote

    private func quiz(from dto: QuestionResponseDTO) -> Quiz {
        Quiz(
            id: dto.questionID,
            prompt: dto.text,
            content: content(from: dto),
            sources: dto.sources.map(source(from:)),
        )
    }

    private func content(from dto: QuestionResponseDTO) -> QuizContent {
        switch dto.format.lowercased() {
        case "essay":
            .essay(submitted: dto.myAnswer?.text.map(EssaySubmission.init(text:)))

        default:
            .choice(
                options: dto.choices,
                submitted: choiceSubmission(from: dto.myAnswer),
            )
        }
    }

    private func choiceSubmission(from dto: MyAnswerResponseDTO?) -> ChoiceSubmission? {
        guard
            let dto,
            let selectedIndex = dto.selectedIndex,
            let isCorrect = dto.correct
        else { return nil }
        return ChoiceSubmission(selectedIndex: selectedIndex, isCorrect: isCorrect)
    }

    private func source(from dto: SourceResponseDTO) -> QuizSource {
        QuizSource(
            filePath: dto.file,
            startLine: dto.startLine,
            endLine: dto.endLine,
            symbol: dto.symbol,
            summary: dto.summary,
            referenceURL: dto.url,
        )
    }

    private func domainError(for error: LearningProjectServiceError) -> QuizDetailError {
        switch error {
        case .invalidRequest:
            .invalidAnswer

        case .unauthorized:
            .unauthorized

        case .projectUnavailable:
            .notFound

        case .questionUnavailable:
            .quizUnavailable

        case .learningSetUnavailable:
            .quizSetUnavailable

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
