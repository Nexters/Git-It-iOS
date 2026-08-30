import Foundation
import Testing

@testable import DomainAuthentication

// MARK: - PolicyConsentUseCaseTests

@Suite("PolicyConsent")
struct PolicyConsentUseCaseTests {

    // MARK: Internal

    @Test
    func `requiredDocuments가 주입된 manifest 문서를 그대로 반환한다`() async throws {
        let documents = try makeDocuments()
        let policyConsent = PolicyConsent(
            manifestDocuments: documents,
            policyConsentRepository: PolicyConsentSpyRepository(),
        )

        let result = try await policyConsent.requiredDocuments()

        #expect(result == documents)
    }

    @Test
    func `필수 문서 ID와 version이 모두 일치하는 저장 기록만 유효로 판정한다`() throws {
        let documents = try makeDocuments()
        let policyConsent = PolicyConsent(
            manifestDocuments: documents,
            policyConsentRepository: PolicyConsentSpyRepository(),
        )
        let validRecords = documents.map {
            PolicyConsentRecord(documentIdentifier: $0.identifier, version: $0.version, acceptedAt: Date())
        }

        #expect(policyConsent.isConsentValid(storedRecords: validRecords, for: documents))
    }

    @Test
    func `storedConsentRecords는 repository 조회 결과를 그대로 전달한다`() async throws {
        let documents = try makeDocuments()
        let records = documents.map {
            PolicyConsentRecord(documentIdentifier: $0.identifier, version: $0.version, acceptedAt: Date())
        }
        let repository = PolicyConsentSpyRepository(storedRecords: records)
        let policyConsent = PolicyConsent(manifestDocuments: documents, policyConsentRepository: repository)

        let result = try await policyConsent.storedConsentRecords()

        #expect(result == records)
    }

    @Test
    func `saveConsentRecords는 repository에 그대로 위임한다`() async throws {
        let documents = try makeDocuments()
        let repository = PolicyConsentSpyRepository()
        let policyConsent = PolicyConsent(manifestDocuments: documents, policyConsentRepository: repository)
        let records = documents.map {
            PolicyConsentRecord(documentIdentifier: $0.identifier, version: $0.version, acceptedAt: Date())
        }

        try await policyConsent.saveConsentRecords(records)

        #expect(await repository.savedRecords() == records)
    }

    @Test
    func `clearConsentRecords는 repository에 그대로 위임한다`() async throws {
        let documents = try makeDocuments()
        let repository = PolicyConsentSpyRepository()
        let policyConsent = PolicyConsent(manifestDocuments: documents, policyConsentRepository: repository)

        try await policyConsent.clearConsentRecords()

        #expect(await repository.didClear())
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

// MARK: - PolicyConsentSpyRepository

private actor PolicyConsentSpyRepository: PolicyConsentRepository {

    // MARK: Lifecycle

    init(storedRecords: [PolicyConsentRecord] = []) {
        self.storedRecords = storedRecords
    }

    // MARK: Internal

    func storedConsentRecords() async throws -> [PolicyConsentRecord] {
        storedRecords
    }

    func saveConsentRecords(_ records: [PolicyConsentRecord]) async throws {
        lastSavedRecords = records
    }

    func clearConsentRecords() async throws {
        cleared = true
    }

    func savedRecords() -> [PolicyConsentRecord]? {
        lastSavedRecords
    }

    func didClear() -> Bool {
        cleared
    }

    // MARK: Private

    private let storedRecords: [PolicyConsentRecord]
    private var lastSavedRecords: [PolicyConsentRecord]?
    private var cleared = false

}
