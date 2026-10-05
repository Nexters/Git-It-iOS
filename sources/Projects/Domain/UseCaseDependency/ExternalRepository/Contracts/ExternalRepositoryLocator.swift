import DomainUseCaseInterface

public protocol ExternalRepositoryLocator: Sendable {
    func location(from url: ExternalRepositoryURL) -> ExternalRepositoryLocation?
}
