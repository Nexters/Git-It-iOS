public struct LoginResponseDTO: CustomDebugStringConvertible, CustomStringConvertible, Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        accessToken: String,
        refreshToken: String,
        needsCuration: Bool,
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.needsCuration = needsCuration
    }

    // MARK: Public

    public let accessToken: String
    public let refreshToken: String
    public let needsCuration: Bool

    public var description: String {
        "LoginResponseDTO(accessToken: <redacted>, refreshToken: <redacted>, needsCuration: \(needsCuration))"
    }

    public var debugDescription: String {
        description
    }

}
