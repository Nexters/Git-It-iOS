import Foundation
import Testing

@testable import CompositionAdapter
@testable import DataLegalConsent
@testable import DomainAuthentication
@testable import InfrastructureStorage

// MARK: - PolicyConsentRepositoryAdapterTests

@Suite("PolicyConsentRepositoryAdapter")
struct PolicyConsentRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `저장한 동의 기록을 Domain 타입으로 손실 없이 다시 조회한다`() async throws {
        let (adapter, suiteName, userDefaults) = try makeAdapter()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let acceptedAt = Date()
        let records = [
            PolicyConsentRecord(documentIdentifier: "privacy-policy", version: "1", acceptedAt: acceptedAt),
            PolicyConsentRecord(documentIdentifier: "terms-of-service", version: "1", acceptedAt: acceptedAt),
        ]

        try await adapter.saveConsentRecords(records)
        let stored = try await adapter.storedConsentRecords()

        #expect(Set(stored.map(\.documentIdentifier)) == Set(records.map(\.documentIdentifier)))
        #expect(stored.allSatisfy { $0.version == "1" })
    }

    @Test
    func `logout에 해당하는 별도 호출이 없어도 저장한 동의 기록이 그대로 유지된다`() async throws {
        let (adapter, suiteName, userDefaults) = try makeAdapter()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        try await adapter.saveConsentRecords([
            PolicyConsentRecord(documentIdentifier: "privacy-policy", version: "1", acceptedAt: Date())
        ])

        let stillStored = try await adapter.storedConsentRecords()

        #expect(stillStored.contains { $0.documentIdentifier == "privacy-policy" })
    }

    @Test
    func `clearConsentRecords는 저장된 모든 동의 기록을 지운다`() async throws {
        let (adapter, suiteName, userDefaults) = try makeAdapter()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        try await adapter.saveConsentRecords([
            PolicyConsentRecord(documentIdentifier: "privacy-policy", version: "1", acceptedAt: Date()),
            PolicyConsentRecord(documentIdentifier: "terms-of-service", version: "1", acceptedAt: Date()),
        ])

        try await adapter.clearConsentRecords()

        let stored = try await adapter.storedConsentRecords()
        #expect(stored.isEmpty)
    }

    // MARK: Private

    private func makeAdapter() throws -> (PolicyConsentRepositoryAdapter, String, UserDefaults) {
        let suiteName = "policy-consent-\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        let store = LocalPolicyConsentStore(
            store: UserDefaultsStore(namespace: "legal-consent", userDefaults: userDefaults)
        )
        return (PolicyConsentRepositoryAdapter(store: store), suiteName, userDefaults)
    }

}
