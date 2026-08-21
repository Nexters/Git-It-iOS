public struct MemberEndpoint: Equatable, Sendable {

    public enum Method: String, Equatable, Sendable {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }

    public static let fetchProfile = Self(method: .get, path: "/api/v1/members/me")

    public static let registerDeviceInfo = Self(method: .post, path: "/api/v1/members/me/device")

    public static let curateMember = Self(method: .post, path: "/api/v1/members/me/curation")

    public static let updatePosition = Self(method: .post, path: "/api/v1/members/me/position")

    public static let updateCareerLevel = Self(method: .post, path: "/api/v1/members/me/career-level")

    public static let withdrawMember = Self(method: .delete, path: "/api/v1/members/me")

    public let method: Method
    public let path: String

    public func headers(accessToken: String) -> [String: String] {
        [
            "Authorization": "Bearer \(accessToken)",
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
    }

}
