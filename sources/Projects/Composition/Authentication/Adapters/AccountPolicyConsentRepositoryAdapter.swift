import DataLegalConsent
import DomainAccount
import Foundation

// MARK: - AccountPolicyConsentRepositoryAdapter

public struct AccountPolicyConsentRepositoryAdapter: PolicyConsentRepository {

    // MARK: Lifecycle

    public init(store: LocalPolicyConsentStore) {
        self.store = store
    }

    // MARK: Public

    public func consents() async throws -> [PolicyConsent] {
        await store.records().map {
            PolicyConsent(documentID: $0.documentIdentifier, version: $0.version, consentedAt: $0.acceptedAt)
        }
    }

    public func record(_ consents: [PolicyConsent]) async throws {
        for consent in consents {
            await store.saveRecord(PolicyConsentRecordDTO(
                documentIdentifier: consent.documentID,
                version: consent.version,
                acceptedAt: consent.consentedAt,
            ))
        }
    }

    public func removeAll() async throws {
        await store.removeAll()
    }

    // MARK: Private

    private let store: LocalPolicyConsentStore

}
