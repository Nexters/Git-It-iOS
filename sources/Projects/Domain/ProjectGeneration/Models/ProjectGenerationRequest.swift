import DomainIdentifier

public struct ProjectGenerationRequest: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        repositoryURL: ExternalRepositoryURL,
        quizLevel: QuizLevel,
    ) {
        self.repositoryURL = repositoryURL
        self.quizLevel = quizLevel
    }

    // MARK: Public

    public let repositoryURL: ExternalRepositoryURL
    public let quizLevel: QuizLevel

}
