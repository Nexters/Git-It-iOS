public enum ExternalRepositoryFetchError: CaseIterable, Equatable, Error, Sendable {
    case offline
    case other
}
