import Foundation

public struct SubmitEssayAnswer: SubmitEssayAnswerUseCase {

    // MARK: Lifecycle

    public init(repository: AnswerRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(
        projectID: String,
        questionID: String,
        text: String,
    ) async throws -> EssayAnswerResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty, trimmed.count <= Self.maximumLength else {
            throw LearningProjectError.invalidRequest
        }

        return try await repository.submitEssayAnswer(
            projectID: projectID,
            questionID: questionID,
            text: trimmed,
        )
    }

    // MARK: Private

    private static let maximumLength = 2000

    private let repository: AnswerRepository

}
