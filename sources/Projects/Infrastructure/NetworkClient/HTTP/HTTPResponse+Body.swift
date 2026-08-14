import Foundation

// MARK: - HTTPResponse.Body

extension HTTPResponse {
    public enum Body: Sendable {
        case decoded(Value)
        case raw(Data)
    }
}
