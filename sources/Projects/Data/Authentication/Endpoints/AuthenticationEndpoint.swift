public struct AuthenticationEndpoint: Equatable, Sendable {

    // MARK: Public

    public enum Method: String, Equatable, Sendable {
        case get = "GET"
        case post = "POST"
    }

    /// 참조 문서 SPEC-DATA-API-001 AUTH-01.
    public static let appleLogin = Self(
        method: .post,
        path: "/api/v1/auth/login/apple",
        requiresBearerAuthentication: false,
    )

    /// 참조 문서 SPEC-DATA-API-001 AUTH-02.
    public static let verifyAccessToken = Self(
        method: .get,
        path: "/api/v1/auth/token",
        requiresBearerAuthentication: true,
    )

    public let method: Method
    public let path: String
    public let requiresBearerAuthentication: Bool

    public func headers(accessToken: String?) -> [String: String] {
        var headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        if requiresBearerAuthentication, let accessToken {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        return headers
    }

}
