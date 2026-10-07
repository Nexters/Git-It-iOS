public enum ProjectGenerationError: CaseIterable, Equatable, Error, Sendable {
    case duplicateRequest
    case invalidRequest
    case unauthorized
    case temporarilyUnavailable
    case unexpected
}
