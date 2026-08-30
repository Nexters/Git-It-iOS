public struct AuthenticationGrant: Equatable, Hashable, Sendable {
    public init(
        id: ID,
        method: AuthenticationMethod,
    ) {
        self.id = id
        self.method = method
    }

    public struct ID: Equatable, Hashable, RawRepresentable, Sendable {
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public let rawValue: String
    }

    public let id: ID
    public let method: AuthenticationMethod
}
