public struct KeychainAccessGroup: Hashable, Sendable {

    // MARK: Lifecycle

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public let rawValue: String

}
