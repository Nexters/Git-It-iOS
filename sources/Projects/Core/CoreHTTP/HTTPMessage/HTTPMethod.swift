// MARK: - HTTPMethod

public enum HTTPMethod: Sendable {
    case get
    case post
    case put
    case patch
    case delete
    case head

    // MARK: Internal

    var requestValue: String {
        switch self {
        case .get: "GET"
        case .post: "POST"
        case .put: "PUT"
        case .patch: "PATCH"
        case .delete: "DELETE"
        case .head: "HEAD"
        }
    }
}
