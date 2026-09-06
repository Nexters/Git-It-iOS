public enum LearningProjectError: CaseIterable, Equatable, Error, Sendable {
    case invalidRequest
    case unauthorized
    case notFound
    case learningSetUnavailable
    case questionUnavailable
    case temporarilyUnavailable
    case unexpected
    case duplicateCreationInProgress
}
