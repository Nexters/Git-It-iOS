import InfrastructureNetworkClient

public struct AuthenticationEndpoint: Equatable, Sendable {

    // MARK: Lifecycle

    private init(
        transportMethod: HTTPMethod,
        path: String,
    ) {
        self.transportMethod = transportMethod
        self.path = path
    }

    // MARK: Public

    public static let appleLogin = Self(
        transportMethod: .post,
        path: "/api/v1/auth/login/apple",
    )

    public static let verifyAccessToken = Self(
        transportMethod: .get,
        path: "/api/v1/auth/token",
    )

    public let path: String

    // MARK: Internal

    let transportMethod: HTTPMethod

    func headers(accessToken: String?) -> HTTPHeaders {
        var headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        if let accessToken {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        return headers
    }

}
