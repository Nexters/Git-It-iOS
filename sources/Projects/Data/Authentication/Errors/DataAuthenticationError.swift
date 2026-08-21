public enum DataAuthenticationError: CaseIterable, Equatable, Error, Sendable {
    case invalidRequest
    case unauthorized
    case temporarilyUnavailable
    case transport
    case decoding
    case unexpectedStatus

    public init(from serverError: ServerAPIError) {
        switch serverError.httpStatus {
        case 400:
            self = .invalidRequest
        case 401:
            self = .unauthorized
        case 500 ... 599:
            self = .temporarilyUnavailable
        default:
            self = .unexpectedStatus
        }
    }
}
