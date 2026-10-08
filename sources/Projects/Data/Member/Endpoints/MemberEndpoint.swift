import InfrastructureNetworkClient

public struct MemberEndpoint: Equatable, Sendable {

    // MARK: Lifecycle

    private init(
        transportMethod: HTTPMethod,
        path: String,
    ) {
        self.transportMethod = transportMethod
        self.path = path
    }

    // MARK: Public

    public static let fetchProfile = Self(
        transportMethod: .get,
        path: "/api/v1/members/me",
    )

    public static let registerDeviceInfo = Self(
        transportMethod: .post,
        path: "/api/v1/members/me/device",
    )

    public static let curateMember = Self(
        transportMethod: .post,
        path: "/api/v1/members/me/curation",
    )

    public static let updatePosition = Self(
        transportMethod: .post,
        path: "/api/v1/members/me/position",
    )

    public static let updateCareerLevel = Self(
        transportMethod: .post,
        path: "/api/v1/members/me/career-level",
    )

    public static let withdrawMember = Self(
        transportMethod: .delete,
        path: "/api/v1/members/me",
    )

    public let path: String

    // MARK: Internal

    let transportMethod: HTTPMethod

    func headers(accessToken: String) -> HTTPHeaders {
        [
            "Authorization": "Bearer \(accessToken)",
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
    }

}
