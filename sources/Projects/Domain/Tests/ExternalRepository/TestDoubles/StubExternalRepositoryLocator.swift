@testable import DomainExternalRepository

struct StubExternalRepositoryLocator: ExternalRepositoryLocator {

    // MARK: Internal

    let location: ExternalRepositoryLocation?

    func location(from _: String) -> ExternalRepositoryLocation? {
        location
    }

}
