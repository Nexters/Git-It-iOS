import DomainAuthentication
import DomainMember
import Foundation

actor PolicyConsentUseCaseMock: PolicyConsentUseCase {

    // MARK: Lifecycle

    init(
        requiredDocuments: [PolicyDocument] = [],
        storedConsentRecords: [PolicyConsentRecord] = [],
    ) {
        requiredDocumentsResult = requiredDocuments
        storedConsentRecordsResult = storedConsentRecords
    }

    // MARK: Internal

    func requiredDocuments() async throws -> [PolicyDocument] {
        requiredDocumentsCallCount += 1
        return requiredDocumentsResult
    }

    func storedConsentRecords() async throws -> [PolicyConsentRecord] {
        storedConsentRecordsResult
    }

    func saveConsentRecords(_ records: [PolicyConsentRecord]) async throws {
        savedRecords.append(records)
        storedConsentRecordsResult = records
    }

    func clearConsentRecords() async throws {
        clearCallCount += 1
        storedConsentRecordsResult = []
    }

    nonisolated func isConsentValid(
        storedRecords: [PolicyConsentRecord],
        for requiredDocuments: [PolicyDocument],
    ) -> Bool {
        PolicyConsentRecord.isConsentValid(storedRecords: storedRecords, for: requiredDocuments)
    }

    func snapshot() -> (requiredDocumentsCallCount: Int, savedRecords: [[PolicyConsentRecord]], clearCallCount: Int) {
        (requiredDocumentsCallCount, savedRecords, clearCallCount)
    }

    // MARK: Private

    private let requiredDocumentsResult: [PolicyDocument]
    private var storedConsentRecordsResult: [PolicyConsentRecord]
    private var requiredDocumentsCallCount = 0
    private var savedRecords = [[PolicyConsentRecord]]()
    private var clearCallCount = 0

}

// MARK: - Test Fixtures
