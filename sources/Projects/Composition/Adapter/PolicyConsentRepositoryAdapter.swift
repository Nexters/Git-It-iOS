import DataLegalConsent
import DomainAuthentication
import Foundation

// MARK: - PolicyConsentRepositoryAdapter

/// 앱 번들 정책 manifest(주입된 `manifestDocuments`)와 설치 단위 `PolicyConsentStore` 사이에서
/// Domain `PolicyConsentRecord`를 변환한다. 계정 식별자는 다루지 않으며 logout으로 저장 기록을
/// 지우지 않는다(FR-041).
struct PolicyConsentRepositoryAdapter: PolicyConsentUseCase {

    // MARK: Lifecycle

    init(
        manifestDocuments: [PolicyDocument],
        store: any PolicyConsentStore,
    ) {
        self.manifestDocuments = manifestDocuments
        self.store = store
    }

    // MARK: Internal

    func requiredDocuments() async throws -> [PolicyDocument] {
        manifestDocuments
    }

    func storedConsentRecords() async throws -> [PolicyConsentRecord] {
        await store.records().map(domainRecord(from:))
    }

    func saveConsentRecords(_ records: [PolicyConsentRecord]) async throws {
        for record in records {
            await store.saveRecord(dtoRecord(from: record))
        }
    }

    func isConsentValid(
        storedRecords: [PolicyConsentRecord],
        for requiredDocuments: [PolicyDocument],
    ) -> Bool {
        PolicyConsentRecord.isConsentValid(storedRecords: storedRecords, for: requiredDocuments)
    }

    // MARK: Private

    private let manifestDocuments: [PolicyDocument]
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
