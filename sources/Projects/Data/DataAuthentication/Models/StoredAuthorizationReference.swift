public struct StoredAuthorizationReference: Equatable, Sendable {
    public init(
        methodIdentifier: String,
        providerSubjectReference: String,
    ) {
        self.methodIdentifier = methodIdentifier
        self.providerSubjectReference = providerSubjectReference
    }

    public let methodIdentifier: String
    public let providerSubjectReference: String
}
