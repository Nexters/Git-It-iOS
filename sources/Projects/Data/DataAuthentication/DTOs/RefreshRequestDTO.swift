public struct RefreshRequestDTO: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable {
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }

    public let refreshToken: String

    public var description: String {
        "RefreshRequestDTO(refreshToken: <redacted>)"
    }

    public var debugDescription: String {
        description
    }
}
