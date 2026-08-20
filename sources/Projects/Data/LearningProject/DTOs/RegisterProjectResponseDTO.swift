// MARK: - RegisterProjectResponseDTO

public struct RegisterProjectResponseDTO: Codable, Equatable, Sendable {
    public init(
        projectId: String,
        status: QuizGenerationStatusDTO,
    ) {
        self.projectId = projectId
        self.status = status
    }

    public let projectId: String
    public let status: QuizGenerationStatusDTO
}

// MARK: - QuizGenerationStatusDTO

public enum QuizGenerationStatusDTO: String, Codable, Equatable, Sendable {
    case ready = "READY"
    case analyzed = "ANALYZED"
    case anchored = "ANCHORED"
    case rejected = "REJECTED"
    case failed = "FAILED"
    case completed = "COMPLETED"
}
