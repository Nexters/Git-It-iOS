import InfrastructureNetworkClient

// MARK: - LearningProjectRequest

public struct LearningProjectRequest: Equatable, Sendable {

    // MARK: Lifecycle

    init(
        method: HTTPMethod,
        path: String,
        queryItems: [String: String] = [:],
    ) {
        transportMethod = method
        self.path = path
        self.queryItems = queryItems
    }

    // MARK: Public

    public let path: String
    public let queryItems: [String: String]

    // MARK: Internal

    let transportMethod: HTTPMethod

}

extension LearningProjectRequest {
    static let basePath = "/api/v1/projects"
}
