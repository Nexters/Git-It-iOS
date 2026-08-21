public enum QuizGenerationEndpoint: Equatable, Sendable {

    case status(projectID: String)
    case retry(projectID: String)

    public var request: LearningProjectRequest {
        switch self {
        case .status(let projectID):
            LearningProjectRequest(method: .get, path: "\(LearningProjectRequest.basePath)/\(projectID)/status")

        case .retry(let projectID):
            LearningProjectRequest(
                method: .post,
                path: "\(LearningProjectRequest.basePath)/\(projectID)/quiz-generation/retry",
            )
        }
    }

}
