public enum DataMemberError: CaseIterable, Equatable, Error, Sendable {
    case invalidRequest
    case unauthorized
    case temporarilyUnavailable
    case transport
    case decoding
    case unexpectedStatus
    case memberUnavailable

    // MARK: Lifecycle

    public init(from serverError: ServerAPIError) {
        switch (serverError.httpStatus, serverError.code) {
        case (400, _):
            self = .invalidRequest
        case (401, _):
            self = .unauthorized
        case (404, "MEMBER-001"):
            self = .memberUnavailable
        case (500 ... 599, _):
            self = .temporarilyUnavailable
        default:
            self = .unexpectedStatus
        }
    }
}
