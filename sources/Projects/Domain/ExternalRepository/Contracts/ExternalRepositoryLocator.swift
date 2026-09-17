import DomainIdentifier

public protocol ExternalRepositoryLocator: Sendable {
    func location(from url: ExternalRepositoryURL) -> ExternalRepositoryLocation?
}
