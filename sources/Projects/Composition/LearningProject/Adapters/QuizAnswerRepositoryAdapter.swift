import DataLearningProject
import DomainUseCaseDependency
import DomainUseCaseInterface

// MARK: - QuizAnswerRepositoryAdapter

public struct QuizAnswerRepositoryAdapter: AnswerRepository {

    // MARK: Lifecycle

    public init(remote: AnswerRemote) {
        self.remote = remote
    }

    // MARK: Public

    public func submit(_ answer: ChoiceAnswer) async throws -> ChoiceGrading {
        do {
            let response = try await remote.submitChoiceAnswer(
                projectID: answer.projectID,
                questionID: answer.quizID,
                request: SubmitChoiceAnswerRequestDTO(selectedIndex: answer.selectedIndex),
            )
            return ChoiceGrading(
                isCorrect: response.correct,
                correctIndex: response.answerIndex,
                explanation: response.explanation,
            )
        } catch let error as LearningProjectServiceError {
            throw domainError(for: error)
        }
    }

    public func submit(_ answer: EssayAnswer) async throws -> EssayGrading {
        do {
            let response = try await remote.submitEssayAnswer(
                projectID: answer.projectID,
                questionID: answer.quizID,
                request: SubmitEssayAnswerRequestDTO(text: answer.text),
            )
            return EssayGrading(
                explanation: response.explanation,
                rubric: [response.rubric.feedback],
            )
        } catch let error as LearningProjectServiceError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: AnswerRemote

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
