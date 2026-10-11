public struct AuthenticationGrant: Equatable, Hashable, Sendable {

    // MARK: Lifecycle

    public init(
        id: String,
        method: SignInMethod,
    ) {
        self.id = id
        self.method = method
    }

    // MARK: Public

    public let id: String
    public let method: SignInMethod

}
