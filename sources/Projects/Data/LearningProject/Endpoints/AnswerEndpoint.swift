public enum AnswerEndpoint: Equatable, Sendable {

    case choice(projectID: String, questionID: String)
    case essay(projectID: String, questionID: String)

    // MARK: Public

    public var request: LearningProjectRequest {
        switch self {
        case .choice(let projectID, let questionID):
            LearningProjectRequest(
                method: .post,
                path: "\(Self.questionPath(projectID: projectID, questionID: questionID))/answers/choice",
            )

        case .essay(let projectID, let questionID):
            LearningProjectRequest(
                method: .post,
                path: "\(Self.questionPath(projectID: projectID, questionID: questionID))/answers/essay",
            )
        }
    }

    // MARK: Private

    private static func questionPath(
        projectID: String,
        questionID: String,
    ) -> String {
        "\(LearningProjectRequest.basePath)/\(projectID)/questions/\(questionID)"
    }

}
