public enum ExternalRepositoryError: CaseIterable, Equatable, Error, Sendable {
    case invalidURLFormat
    case offline
    case other
}
