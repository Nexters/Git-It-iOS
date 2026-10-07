public struct SignedInAccount: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        id: AccountID,
        displayName: String?,
        needsCuration: Bool,
    ) {
        self.id = id
        self.displayName = displayName
        self.needsCuration = needsCuration
    }

    // MARK: Public

    public let id: AccountID
    public let displayName: String?
    public let needsCuration: Bool

}
