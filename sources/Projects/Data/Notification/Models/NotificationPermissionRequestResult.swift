// MARK: - NotificationPermissionRequestResult

public enum NotificationPermissionRequestResult: Equatable, Sendable {
    case authorized
    case declined
    case previouslyDenied
}
