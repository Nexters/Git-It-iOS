public enum MemberError: CaseIterable, Equatable, Error, Sendable {
    case invalidRequest
    case unauthorized
    case memberUnavailable
    case temporarilyUnavailable
}
