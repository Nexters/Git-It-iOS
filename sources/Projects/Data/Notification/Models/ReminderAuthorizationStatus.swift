// MARK: - ReminderAuthorizationStatus

public enum ReminderAuthorizationStatus: Equatable, Sendable {
    case authorized
    case declined
    case previouslyDenied
}
