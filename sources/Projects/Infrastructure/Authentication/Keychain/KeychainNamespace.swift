public struct KeychainNamespace: Hashable, Sendable {
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public let rawValue: String
}
