public struct AuthenticationEndpoint: Equatable, Sendable {

    public enum Method: String, Equatable, Sendable {
        case get = "GET"
        case post = "POST"
    }

    public static let appleLogin = Self(
        method: .post,
        path: "/api/v1/auth/login/apple",
    )

    public static let verifyAccessToken = Self(
        method: .get,
        path: "/api/v1/auth/token",
    )

    public let method: Method
    public let path: String

    public func headers(accessToken: String?) -> [String: String] {
        var headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        if let accessToken {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        return headers
    }

}
