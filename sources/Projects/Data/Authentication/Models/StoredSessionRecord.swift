import Foundation

// MARK: - StoredSessionRecord

public struct StoredSessionRecord: Codable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        accessToken: String,
        refreshToken: String,
        accessTokenExpiresAt: Date?,
        refreshTokenExpiresAt: Date?,
        needsCuration: Bool,
        acceptedLegalVersions: [String],
        acceptedAt: Date?,
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessTokenExpiresAt = accessTokenExpiresAt
        self.refreshTokenExpiresAt = refreshTokenExpiresAt
        self.needsCuration = needsCuration
        self.acceptedLegalVersions = acceptedLegalVersions
        self.acceptedAt = acceptedAt
    }

    // MARK: Public

    public let accessToken: String
    public let refreshToken: String
    public let accessTokenExpiresAt: Date?
    public let refreshTokenExpiresAt: Date?
    public let needsCuration: Bool
    public let acceptedLegalVersions: [String]
    public let acceptedAt: Date?

}
