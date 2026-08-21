public enum BookmarkEndpoint: Equatable, Sendable {

    case set(projectID: String, questionID: String)
    case list(projectID: String?)

    // MARK: Public

    public var request: LearningProjectRequest {
        switch self {
        case .set(let projectID, let questionID):
            LearningProjectRequest(
                method: .post,
                path: "\(LearningProjectRequest.basePath)/\(projectID)/questions/\(questionID)/bookmark",
            )

        case .list(let projectID):
            LearningProjectRequest(
                method: .get,
                path: "\(LearningProjectRequest.basePath)/bookmarks",
                queryItems: projectID.map { ["projectId": $0] } ?? [:],
            )
        }
    }

}
