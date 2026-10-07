// MARK: - AppleSignInCredential

public struct AppleSignInCredential: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        userID: String,
        identityToken: String,
    ) {
        self.userID = userID
        self.identityToken = identityToken
    }

    // MARK: Public

    public let userID: String
    public let identityToken: String

    public var description: String {
        "AppleSignInCredential(<redacted>)"
    }

    public var debugDescription: String {
        description
    }

}
