public enum UserInfoError: CaseIterable, Equatable, Error, Sendable {
    case invalidRequest
    case unauthorized
    case memberUnavailable
    case temporarilyUnavailable
}
