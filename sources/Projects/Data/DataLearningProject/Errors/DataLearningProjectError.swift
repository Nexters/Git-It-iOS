public enum DataLearningProjectError: CaseIterable, Equatable, Error, Sendable {
    case invalidRequest
    case unauthorized
    case notFound
    case serverError
    case unexpected
}
