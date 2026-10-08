import DomainUseCaseDependency
@testable import DomainUseCaseInterface

actor InMemoryPolicyConsentRepository: PolicyConsentRepository {

    // MARK: Lifecycle

    init(consents: [PolicyConsent] = []) {
        storedConsents = consents
    }

    // MARK: Internal

    private(set) var storedConsents: [PolicyConsent]
    private(set) var removeAllCount = 0

    func consents() async throws -> [PolicyConsent] {
        storedConsents
    }

    func record(_ consents: [PolicyConsent]) async throws {
        let documentIDs = Set(consents.map(\.documentID))
        storedConsents = storedConsents.filter { !documentIDs.contains($0.documentID) } + consents
    }

    func removeAll() async throws {
        removeAllCount += 1
        storedConsents.removeAll()
    }

}
