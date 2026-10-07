import DomainIdentifier

public protocol QuizSetRepository: Sendable {
    func quizSet(
        _ setID: QuizSetID,
        in projectID: ProjectID,
    ) async throws -> QuizSet
}
