public struct RegisterProjectRequestDTO: Encodable, Equatable, Sendable {
    public init(
        githubRepoURL: String,
        quizLevel: QuizLevelDTO,
    ) {
        self.githubRepoURL = githubRepoURL
        self.quizLevel = quizLevel
    }

    public let githubRepoURL: String
    public let quizLevel: QuizLevelDTO

    private enum CodingKeys: String, CodingKey {
        case githubRepoURL = "githubRepoUrl"
        case quizLevel
    }
}
