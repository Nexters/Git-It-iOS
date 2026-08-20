// MARK: - RegisterProjectRequestDTO

public struct RegisterProjectRequestDTO: Codable, Equatable, Sendable {
    public init(
        githubRepoUrl: String,
        quizLevel: QuizLevelDTO?,
    ) {
        self.githubRepoUrl = githubRepoUrl
        self.quizLevel = quizLevel
    }

    public let githubRepoUrl: String
    public let quizLevel: QuizLevelDTO?
}

// MARK: - QuizLevelDTO

public enum QuizLevelDTO: String, Codable, Equatable, Sendable {
    case l1 = "L1"
    case l2 = "L2"
    case l3 = "L3"
}
