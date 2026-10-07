public enum ProjectError: CaseIterable, Equatable, Error, Sendable {
    case invalidRequest
    case notFound
    case unauthorized
    case temporarilyUnavailable
    case unexpected
}
