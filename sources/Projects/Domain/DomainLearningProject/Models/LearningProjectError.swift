public enum LearningProjectError: CaseIterable, Equatable, Error, Sendable {
    case invalidRequest
    case unauthorized
    case notFound
    case unexpected
}
