public struct PolicyConsentStatus: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        documents: [PolicyDocument],
        consents: [PolicyConsent],
        isSatisfied: Bool,
    ) {
        self.documents = documents
        self.consents = consents
        self.isSatisfied = isSatisfied
    }

    // MARK: Public

    public let documents: [PolicyDocument]
    public let consents: [PolicyConsent]
    public let isSatisfied: Bool

}
