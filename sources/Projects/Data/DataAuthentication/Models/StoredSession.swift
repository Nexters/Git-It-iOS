import Foundation

public struct StoredSession: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable {
    public init(
        accessToken: String,
        refreshToken: String,
        accessExpiresAt: Date,
        user: SessionResponseDTO.User,
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessExpiresAt = accessExpiresAt
        self.user = user
    }

    public let accessToken: String
    public let refreshToken: String
    public let accessExpiresAt: Date
    public let user: SessionResponseDTO.User

    public var description: String {
        "StoredSession(<redacted>)"
    }

    public var debugDescription: String {
        description
    }
}
