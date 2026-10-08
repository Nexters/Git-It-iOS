import DomainUseCaseInterface
import Foundation

actor AccountUseCaseConsentMock {

    // MARK: Lifecycle

    init(status: PolicyConsentStatus = PolicyConsentStatus(
        documents: [],
        consents: [],
        isSatisfied: false,
    )) {
        self.status = status
    }

    // MARK: Internal

    nonisolated var policyConsentStatus: @Sendable () async throws -> PolicyConsentStatus {
        { await self.loadStatus() }
    }

    nonisolated var consent: @Sendable ([PolicyDocumentID]) async throws -> Void {
        { await self.recordConsent($0) }
    }

    func loadStatus() -> PolicyConsentStatus {
        statusCallCount += 1
        return status
    }

    func recordConsent(_ documentIDs: [PolicyDocumentID]) {
        consentedDocumentIDs.append(documentIDs)
    }

    func snapshot() -> (statusCallCount: Int, consentedDocumentIDs: [[PolicyDocumentID]]) {
        (statusCallCount, consentedDocumentIDs)
    }

    // MARK: Private

    private let status: PolicyConsentStatus
    private var statusCallCount = 0
    private var consentedDocumentIDs = [[PolicyDocumentID]]()

}
