// MARK: - RequestTransportError

public enum RequestTransportError: Error, Equatable, Sendable {
    case cancelled
    case timedOut
    case connectionFailed
}
