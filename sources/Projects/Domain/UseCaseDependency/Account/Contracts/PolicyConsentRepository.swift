import DomainUseCaseInterface

public protocol PolicyConsentRepository: Sendable {
    func consents() async throws -> [PolicyConsent]
    func record(_ consents: [PolicyConsent]) async throws
    func removeAll() async throws
}
