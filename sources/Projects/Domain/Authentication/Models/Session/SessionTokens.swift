import Foundation

public struct SessionTokens: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        accessToken: String,
        refreshToken: String,
        accessTokenExpiresAt: Date?,
        refreshTokenExpiresAt: Date?,
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessTokenExpiresAt = accessTokenExpiresAt
        self.refreshTokenExpiresAt = refreshTokenExpiresAt
    }

    // MARK: Public

    public let accessToken: String
    public let refreshToken: String
    public let accessTokenExpiresAt: Date?
    public let refreshTokenExpiresAt: Date?

}
