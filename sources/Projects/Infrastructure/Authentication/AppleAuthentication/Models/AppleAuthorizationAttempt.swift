import Foundation

public struct AppleAuthorizationAttempt: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable {
    public let id: String
    public let nonce: String
    public let state: String
    public let expiresAt: Date

    public var description: String {
        "AppleAuthorizationAttempt(<redacted>)"
    }

    public var debugDescription: String {
        description
    }
}
