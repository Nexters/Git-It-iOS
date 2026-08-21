// MARK: - HTTPMethod

public enum HTTPMethod: String, Equatable, Sendable {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
}

// MARK: - LearningProjectRequest

public struct LearningProjectRequest: Equatable, Sendable {
    public init(
        method: HTTPMethod,
        path: String,
        queryItems: [String: String] = [:],
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
    }

    public let method: HTTPMethod
    public let path: String
    public let queryItems: [String: String]
}

extension LearningProjectRequest {
    static let basePath = "/api/v1/projects"
}
