public protocol PolicyConsentUseCase: Sendable {
    func requiredDocuments() async throws -> [PolicyDocument]

    func storedConsentRecords() async throws -> [PolicyConsentRecord]

    func saveConsentRecords(_ records: [PolicyConsentRecord]) async throws

    func clearConsentRecords() async throws

    func isConsentValid(
        storedRecords: [PolicyConsentRecord],
        for requiredDocuments: [PolicyDocument],
    ) -> Bool
}
