import Foundation
import Testing

@testable import CompositionAdapter
@testable import DataLegalConsent
@testable import DomainAuthentication

// MARK: - PolicyConsentRepositoryAdapterTests

@Suite("PolicyConsentRepositoryAdapter")
struct PolicyConsentRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `requiredDocuments가 주입된 manifest 문서를 그대로 반환한다`() async throws {
        let documents = try makeDocuments()
        let adapter = PolicyConsentRepositoryAdapter(manifestDocuments: documents, store: FakePolicyConsentStore())

        let result = try await adapter.requiredDocuments()

        #expect(result == documents)
    }

    @Test
    func `필수 문서 ID와 version이 모두 일치하는 저장 기록만 유효로 판정한다`() throws {
        let documents = try makeDocuments()
        let adapter = PolicyConsentRepositoryAdapter(manifestDocuments: documents, store: FakePolicyConsentStore())
        let validRecords = documents.map {
            PolicyConsentRecord(documentIdentifier: $0.identifier, version: $0.version, acceptedAt: Date())
        }

        #expect(adapter.isConsentValid(storedRecords: validRecords, for: documents))
    }

    @Test
    func `한 문서만 version이 바뀌면 그 문서 기록만 무효화된다`() throws {
        let documents = try makeDocuments()
        let adapter = PolicyConsentRepositoryAdapter(manifestDocuments: documents, store: FakePolicyConsentStore())
        let staleRecords = [
            PolicyConsentRecord(documentIdentifier: "privacy-policy", version: "0", acceptedAt: Date()),
            PolicyConsentRecord(documentIdentifier: "terms-of-service", version: "1", acceptedAt: Date()),
        ]

        #expect(adapter.isConsentValid(storedRecords: staleRecords, for: documents) == false)
    }

    @Test
    func `저장한 동의 기록을 Domain 타입으로 손실 없이 다시 조회한다`() async throws {
        let documents = try makeDocuments()
        let store = FakePolicyConsentStore()
        let adapter = PolicyConsentRepositoryAdapter(manifestDocuments: documents, store: store)
        let acceptedAt = Date()
        let records = documents.map {
            PolicyConsentRecord(documentIdentifier: $0.identifier, version: $0.version, acceptedAt: acceptedAt)
        }

        try await adapter.saveConsentRecords(records)
        let stored = try await adapter.storedConsentRecords()

        #expect(Set(stored.map(\.documentIdentifier)) == Set(records.map(\.documentIdentifier)))
        #expect(stored.allSatisfy { $0.version == "1" })
    }

    @Test
    func `logout에 해당하는 별도 호출이 없어도 저장한 동의 기록이 그대로 유지된다`() async throws {
        let documents = try makeDocuments()
        let store = FakePolicyConsentStore()
        let adapter = PolicyConsentRepositoryAdapter(manifestDocuments: documents, store: store)
        try await adapter.saveConsentRecords([
            PolicyConsentRecord(documentIdentifier: "privacy-policy", version: "1", acceptedAt: Date())
        ])

        let stillStored = try await adapter.storedConsentRecords()

        #expect(stillStored.contains { $0.documentIdentifier == "privacy-policy" })
    }

    // MARK: Private

    private func makeDocuments() throws -> [PolicyDocument] {
        [
            PolicyDocument(
                identifier: "privacy-policy",
                displayName: "개인정보 처리방침",
                version: "1",
                approvedURL: try #require(URL(string: "https://git-it-service-policy.notion.site/privacy")),
                isRequired: true,
            ),
            PolicyDocument(
                identifier: "terms-of-service",
                displayName: "서비스 이용 약관",
                version: "1",
                approvedURL: try #require(URL(string: "https://git-it-service-policy.notion.site/terms")),
                isRequired: true,
            ),
        ]
    }

}

// MARK: - FakePolicyConsentStore

private actor FakePolicyConsentStore: PolicyConsentStore {

    // MARK: Internal

    func records() async -> [PolicyConsentRecordDTO] {
        storage
    }

    func saveRecord(_ record: PolicyConsentRecordDTO) async {
        storage.removeAll { $0.documentIdentifier == record.documentIdentifier }
        storage.append(record)
    }

    func removeAll() async {
        storage.removeAll()
    }

    // MARK: Private

    private var storage = [PolicyConsentRecordDTO]()

}
