// MARK: - HTTPClientError

public enum HTTPClientError: Error, Equatable, Sendable {
    case invalidURL
    case requestEncodingFailed
    case connectionFailed
    case timedOut
    case cancelled
    case responseDecodingFailed
}
