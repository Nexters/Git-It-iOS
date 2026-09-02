public protocol ExternalRepositoryURLParser: Sendable {

    func location(from url: String) -> ExternalRepositoryLocation?

}
