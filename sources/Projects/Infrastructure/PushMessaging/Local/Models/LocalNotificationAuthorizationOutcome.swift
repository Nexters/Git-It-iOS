// MARK: - LocalNotificationAuthorizationOutcome

public enum LocalNotificationAuthorizationOutcome: Sendable, Equatable {
    case authorized
    case declined
    case previouslyDenied
}
