import DataLegalConsent
import DomainAuthentication
import Foundation

// MARK: - PolicyConsentRepositoryAdapter

struct PolicyConsentRepositoryAdapter: PolicyConsentRepository {

    // MARK: Lifecycle

    init(store: any PolicyConsentStore) {
        self.store = store
    }

    // MARK: Internal

    func storedConsentRecords() async throws -> [PolicyConsentRecord] {
        await store.records().map(domainRecord(from:))
    }

    func saveConsentRecords(_ records: [PolicyConsentRecord]) async throws {
        for record in records {
            await store.saveRecord(dtoRecord(from: record))
        }
    }

    func clearConsentRecords() async throws {
        await store.removeAll()
    }

    // MARK: Private

    private let store: any PolicyConsentStore

    private func domainRecord(from dto: PolicyConsentRecordDTO) -> PolicyConsentRecord {
        PolicyConsentRecord(
            documentIdentifier: dto.documentIdentifier,
            version: dto.version,
            acceptedAt: dto.acceptedAt,
        )
    }

    private func dtoRecord(from record: PolicyConsentRecord) -> PolicyConsentRecordDTO {
        PolicyConsentRecordDTO(
            documentIdentifier: record.documentIdentifier,
            version: record.version,
            acceptedAt: record.acceptedAt,
        )
    }

}
