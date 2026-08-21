import DataLearningProject
import DomainLearningProject

// MARK: - AnswerRepositoryAdapter

struct AnswerRepositoryAdapter: AnswerRepository {

    // MARK: Lifecycle

    init(remote: AnswerRemote) {
        self.remote = remote
    }

    // MARK: Internal

    func submitChoiceAnswer(
        projectID: String,
        questionID: String,
        selectedIndex: Int,
    ) async throws -> ChoiceAnswerResult {
        do {
            let response = try await remote.submitChoiceAnswer(
                projectID: projectID,
                questionID: questionID,
                request: SubmitChoiceAnswerRequestDTO(selectedIndex: selectedIndex),
            )
            return ChoiceAnswerResult(
                correct: response.correct,
                answerIndex: response.answerIndex,
                explanation: response.explanation,
            )
        } catch let error as DataLearningProjectError {
            throw domainError(for: error)
        }
    }

    func submitEssayAnswer(
        projectID: String,
        questionID: String,
        text: String,
    ) async throws -> EssayAnswerResult {
        do {
            let response = try await remote.submitEssayAnswer(
                projectID: projectID,
                questionID: questionID,
                request: SubmitEssayAnswerRequestDTO(text: text),
            )
            return EssayAnswerResult(
                explanation: response.explanation,
                rubric: Rubric(criteria: [response.rubric.feedback]),
            )
        } catch let error as DataLearningProjectError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: AnswerRemote

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
