public protocol PolicyConsentRepository: Sendable {
    func storedConsentRecords() async throws -> [PolicyConsentRecord]

    func saveConsentRecords(_ records: [PolicyConsentRecord]) async throws

    func clearConsentRecords() async throws
}
