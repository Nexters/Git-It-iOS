public enum DataLearningProjectError: CaseIterable, Equatable, Error, Sendable {
    case invalidRequest
    case unauthorized
    case temporarilyUnavailable
    case transport
    case decoding
    case unexpectedStatus
    case projectUnavailable
    case questionUnavailable
    case learningSetUnavailable
    case generationRetryUnavailable

    // MARK: Lifecycle

    public init(from serverError: ServerAPIError) {
        switch (serverError.httpStatus, serverError.code) {
        case (400, _):
            self = .invalidRequest
        case (401, _):
            self = .unauthorized
        case (404, "PROJECT-001"):
            self = .projectUnavailable
        case (404, "QUIZ-005"):
            self = .questionUnavailable
        case (404, "QUIZ-006"):
            self = .learningSetUnavailable
        case (409, "QUIZ-007"):
            self = .generationRetryUnavailable
        case (500 ... 599, _):
            self = .temporarilyUnavailable
        default:
            self = .unexpectedStatus
        }
    }
}
