public struct PolicyConsent: PolicyConsentUseCase, Sendable {

    // MARK: Lifecycle

    public init(
        manifestDocuments: [PolicyDocument],
        policyConsentRepository: any PolicyConsentRepository,
    ) {
        self.manifestDocuments = manifestDocuments
        self.policyConsentRepository = policyConsentRepository
    }

    // MARK: Public

    public func requiredDocuments() async throws -> [PolicyDocument] {
        manifestDocuments
    }

    public func storedConsentRecords() async throws -> [PolicyConsentRecord] {
        try await policyConsentRepository.storedConsentRecords()
    }

    public func saveConsentRecords(_ records: [PolicyConsentRecord]) async throws {
        try await policyConsentRepository.saveConsentRecords(records)
    }

    public func clearConsentRecords() async throws {
        try await policyConsentRepository.clearConsentRecords()
    }

    public func isConsentValid(
        storedRecords: [PolicyConsentRecord],
        for requiredDocuments: [PolicyDocument],
    ) -> Bool {
        PolicyConsentRecord.isConsentValid(storedRecords: storedRecords, for: requiredDocuments)
    }

    // MARK: Private

    private let manifestDocuments: [PolicyDocument]
    private let policyConsentRepository: any PolicyConsentRepository

}
