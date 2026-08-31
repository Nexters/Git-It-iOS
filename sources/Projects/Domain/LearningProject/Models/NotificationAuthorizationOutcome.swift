public enum NotificationAuthorizationOutcome: Sendable, Equatable {
    case authorized
    case declined
    case previouslyDenied
}
