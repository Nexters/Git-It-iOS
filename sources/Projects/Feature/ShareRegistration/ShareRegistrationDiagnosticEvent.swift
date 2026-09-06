public enum ShareRegistrationDiagnosticEvent: Equatable, Sendable {
    case sharedItemUnavailable
    case repositoryLinkRejected
    case sessionResolved(ShareRegistrationSessionState)
    case repositoryLookupFailed(reason: String)
    case registrationFailed(reason: String)
    case registrationSucceeded
    case generationReminderEnqueued
}
