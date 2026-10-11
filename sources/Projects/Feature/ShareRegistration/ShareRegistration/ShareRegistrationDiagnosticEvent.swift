import DomainUseCaseInterface

public enum ShareRegistrationDiagnosticEvent: Equatable, Sendable {
    case sharedItemUnavailable
    case repositoryLinkRejected
    case signInAvailabilityResolved(SignInAvailability)
    case repositoryLookupFailed(reason: String)
    case registrationFailed(reason: String)
    case registrationSucceeded
    case generationInProgressBlocked
    case generationStateUnverified
}
