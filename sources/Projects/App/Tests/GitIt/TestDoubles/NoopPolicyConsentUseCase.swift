import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopPolicyConsentUseCase: PolicyConsentUseCase {
    func requiredDocuments() async throws -> [PolicyDocument] {
        []
    }

    func storedConsentRecords() async throws -> [PolicyConsentRecord] {
        []
    }

    func saveConsentRecords(_: [PolicyConsentRecord]) async throws { }
    func clearConsentRecords() async throws { }
    func isConsentValid(
        storedRecords _: [PolicyConsentRecord],
        for _: [PolicyDocument],
    ) -> Bool {
        false
    }
}
