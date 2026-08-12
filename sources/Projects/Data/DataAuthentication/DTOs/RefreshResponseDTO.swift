import Foundation

public struct RefreshResponseDTO: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable {
    public init(
        accessToken: String,
        accessExpiresAt: Date,
        replacementRefreshToken: String?,
    ) {
        self.accessToken = accessToken
        self.accessExpiresAt = accessExpiresAt
        self.replacementRefreshToken = replacementRefreshToken
    }

    public let accessToken: String
    public let accessExpiresAt: Date
    public let replacementRefreshToken: String?

    public var description: String {
        "RefreshResponseDTO(session: <redacted>)"
    }

    public var debugDescription: String {
        description
    }
}
