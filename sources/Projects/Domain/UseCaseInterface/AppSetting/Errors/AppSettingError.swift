public enum AppSettingError: CaseIterable, Equatable, Error, Sendable {
    case invalidRequest
    case unauthorized
    case temporarilyUnavailable
}
