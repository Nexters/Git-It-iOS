// MARK: - NotificationAuthorizationStatus

public enum NotificationAuthorizationStatus: Sendable, Equatable {
    case authorized
    case declined
    case previouslyDenied
}
