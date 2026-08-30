public struct AuthenticatedUser: Equatable, Sendable {
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
