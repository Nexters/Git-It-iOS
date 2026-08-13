import Foundation

public struct StoredLoginSession: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        accessToken: String,
        refreshToken: String,
        accessExpiresAt: Date,
        user: LoginSessionResponseDTO.User,
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessExpiresAt = accessExpiresAt
        self.user = user
    }

    // MARK: Public

    public let accessToken: String
    public let refreshToken: String
    public let accessExpiresAt: Date
    public let user: LoginSessionResponseDTO.User

    public var description: String {
        "StoredLoginSession(<redacted>)"
    }

    public var debugDescription: String {
        description
    }

}
