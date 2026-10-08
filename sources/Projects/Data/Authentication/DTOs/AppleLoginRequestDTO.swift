public struct AppleLoginRequestDTO: CustomDebugStringConvertible, CustomStringConvertible, Encodable, Equatable, Sendable {
    public init(idToken: String) {
        self.idToken = idToken
    }

    public let idToken: String

    public var description: String {
        "AppleLoginRequestDTO(idToken: <redacted>)"
    }

    public var debugDescription: String {
        description
    }
}
