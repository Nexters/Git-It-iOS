import Foundation
import InfrastructureStorage
import Testing

@testable import DataLegalConsent

@Suite("LocalPolicyConsentStore")
struct LocalPolicyConsentStoreTests {

    // MARK: Internal

    @Test
    func `저장한 문서별 기록을 그대로 조회한다`() async {
        let (store, _) = makeStore()
        let privacy = PolicyConsentRecordDTO(documentIdentifier: "privacy-policy", version: "1", acceptedAt: Date())
        let terms = PolicyConsentRecordDTO(documentIdentifier: "terms-of-service", version: "1", acceptedAt: Date())

        await store.saveRecord(privacy)
        await store.saveRecord(terms)

        let records = await store.records()
        #expect(Set(records.map(\.documentIdentifier)) == ["privacy-policy", "terms-of-service"])
    }

    @Test
    func `같은 문서 ID를 다시 저장하면 이전 기록을 교체하고 다른 문서 기록에는 영향이 없다`() async {
        let (store, _) = makeStore()
        let firstVersion = PolicyConsentRecordDTO(documentIdentifier: "privacy-policy", version: "1", acceptedAt: Date())
        let terms = PolicyConsentRecordDTO(documentIdentifier: "terms-of-service", version: "1", acceptedAt: Date())
        await store.saveRecord(firstVersion)
        await store.saveRecord(terms)

        let secondVersion = PolicyConsentRecordDTO(documentIdentifier: "privacy-policy", version: "2", acceptedAt: Date())
        await store.saveRecord(secondVersion)

        let records = await store.records()
        #expect(records.count == 2)
        #expect(records.first { $0.documentIdentifier == "privacy-policy" }?.version == "2")
        #expect(records.first { $0.documentIdentifier == "terms-of-service" }?.version == "1")
    }

    @Test
    func `logout과 무관하게 유지되고 앱 데이터 삭제를 시뮬레이션하면 부재로 돌아간다`() async throws {
        let suiteName = "policy-consent-\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let store = LocalPolicyConsentStore(store: UserDefaultsStore(namespace: "legal-consent", userDefaults: userDefaults))
        await store.saveRecord(PolicyConsentRecordDTO(documentIdentifier: "privacy-policy", version: "1", acceptedAt: Date()))

        let afterLogout = LocalPolicyConsentStore(store: UserDefaultsStore(
            namespace: "legal-consent",
            userDefaults: userDefaults,
        ))
        #expect(await afterLogout.records().isEmpty == false)

        userDefaults.removePersistentDomain(forName: suiteName)

        let afterAppDataDeletion = LocalPolicyConsentStore(store: UserDefaultsStore(
            namespace: "legal-consent",
            userDefaults: userDefaults,
        ))
        #expect(await afterAppDataDeletion.records().isEmpty)
    }

    // MARK: Private

    private func makeStore() -> (LocalPolicyConsentStore, UserDefaults) {
        let suiteName = "policy-consent-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        return (
            LocalPolicyConsentStore(store: UserDefaultsStore(namespace: "legal-consent", userDefaults: userDefaults)),
            userDefaults,
        )
    }

}
