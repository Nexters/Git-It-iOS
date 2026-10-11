public struct SignInRecord: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        account: SignedInAccount,
        isAccountAvailable: Bool,
    ) {
        self.account = account
        self.isAccountAvailable = isAccountAvailable
    }

    // MARK: Public

    public let account: SignedInAccount
    public let isAccountAvailable: Bool

}
