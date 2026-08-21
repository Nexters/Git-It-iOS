public enum ProjectEndpoint: Equatable, Sendable {

    case register
    case list(page: Int, size: Int)
    case detail(projectID: String)
    case delete(projectID: String)

    // MARK: Public

    public var request: LearningProjectRequest {
        switch self {
        case .register:
            LearningProjectRequest(method: .post, path: LearningProjectRequest.basePath)

        case .list(let page, let size):
            LearningProjectRequest(
                method: .get,
                path: LearningProjectRequest.basePath,
                queryItems: ["page": String(page), "size": String(size)],
            )

        case .detail(let projectID):
            LearningProjectRequest(method: .get, path: "\(LearningProjectRequest.basePath)/\(projectID)")

        case .delete(let projectID):
            LearningProjectRequest(method: .delete, path: "\(LearningProjectRequest.basePath)/\(projectID)")
        }
    }

}
