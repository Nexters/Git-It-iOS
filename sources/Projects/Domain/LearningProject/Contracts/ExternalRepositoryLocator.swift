public protocol ExternalRepositoryLocator: Sendable {

    func location(from url: String) -> ExternalRepositoryLocation?

}
