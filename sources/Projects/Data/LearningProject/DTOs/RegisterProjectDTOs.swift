// MARK: - RegisterProjectRequestDTO

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

// MARK: - QuizLevelDTO

public enum QuizLevelDTO: String, Decodable, Encodable, Equatable, Sendable {
    case l1 = "L1"
    case l2 = "L2"
    case l3 = "L3"
}

// MARK: - RegisterProjectResponseDTO

public struct RegisterProjectResponseDTO: Decodable, Equatable, Sendable {
    public init(
        projectID: String,
        status: String,
    ) {
        self.projectID = projectID
        self.status = status
    }

    public let projectID: String
    public let status: String

    private enum CodingKeys: String, CodingKey {
        case projectID = "projectId"
        case status
    }
}
