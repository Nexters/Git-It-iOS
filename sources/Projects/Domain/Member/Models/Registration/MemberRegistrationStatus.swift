public enum MemberRegistrationStatus: Equatable, Sendable {
    case registered(profile: MemberProfile)
    case unregistered
    case retryableFailure
}
