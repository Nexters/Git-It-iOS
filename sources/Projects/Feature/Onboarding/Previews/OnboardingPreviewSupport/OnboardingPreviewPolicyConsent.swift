import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

struct OnboardingPreviewPolicyConsent: PolicyConsentUseCase {
    func requiredDocuments() async throws -> [PolicyDocument] {
        OnboardingPreviewSupport.requiredDocuments
    }

    func storedConsentRecords() async throws -> [PolicyConsentRecord] {
        []
    }

    func saveConsentRecords(_: [PolicyConsentRecord]) async throws { }

    func clearConsentRecords() async throws { }

    func isConsentValid(
        storedRecords: [PolicyConsentRecord],
        for requiredDocuments: [PolicyDocument],
    ) -> Bool {
        PolicyConsentRecord.isConsentValid(storedRecords: storedRecords, for: requiredDocuments)
    }
}
