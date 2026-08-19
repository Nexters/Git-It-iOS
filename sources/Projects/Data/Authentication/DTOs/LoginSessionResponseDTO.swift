import Foundation

public struct LoginSessionResponseDTO: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        user: User,
        accessToken: String,
        refreshToken: String,
        accessExpiresAt: Date,
    ) {
        self.user = user
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessExpiresAt = accessExpiresAt
    }

    // MARK: Public

    public struct User: Equatable, Sendable {
        public init(
            id: String,
            availability: Availability,
            displayName: String?,
        ) {
            self.id = id
            self.availability = availability
            self.displayName = displayName
        }

        public enum Availability: CaseIterable, Equatable, Sendable {
            case available
            case unavailable
        }

        public let id: String
        public let availability: Availability
        public let displayName: String?
    }

    public let user: User
    public let accessToken: String
    public let refreshToken: String
    public let accessExpiresAt: Date

    public var description: String {
        "LoginSessionResponseDTO(user: \(user.id), session: <redacted>)"
    }

    public var debugDescription: String {
        description
    }

}
