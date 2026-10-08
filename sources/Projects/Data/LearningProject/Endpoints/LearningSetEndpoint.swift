public enum LearningSetEndpoint: Equatable, Sendable {

    case detail(projectID: String, setID: String)

    public var request: LearningProjectRequest {
        switch self {
        case .detail(let projectID, let setID):
            LearningProjectRequest(
                method: .get,
                path: "\(LearningProjectRequest.basePath)/\(projectID)/sets/\(setID)",
            )
        }
    }

}
