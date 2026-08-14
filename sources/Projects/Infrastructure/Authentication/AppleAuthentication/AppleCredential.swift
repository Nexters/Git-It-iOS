import Foundation

public struct AppleCredential: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        userID: String,
        identityToken: Data?,
        authorizationCode: Data?,
        email: String?,
        fullName: String?,
        requestedScopes: [Scope] = [.email, .fullName],
    ) {
        self.userID = userID
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.email = email
        self.fullName = fullName
        self.requestedScopes = requestedScopes
    }

    // MARK: Public

    public enum Scope: CaseIterable, Equatable, Sendable {
        case email
        case fullName
    }

    public let userID: String
    public let identityToken: Data?
    public let authorizationCode: Data?
    public let email: String?
    public let fullName: String?
    public let requestedScopes: [Scope]

    public var description: String {
        "AppleCredential(<redacted>)"
    }

    public var debugDescription: String {
        description
    }

}
