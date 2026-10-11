import DomainUseCaseDependency
import DomainUseCaseInterface

struct StubRepositoryURLParser: ExternalRepositoryLocator {

    // MARK: Lifecycle

    init(location: ExternalRepositoryLocation?) {
        self.location = location
    }

    // MARK: Internal

    func location(from _: ExternalRepositoryURL) -> ExternalRepositoryLocation? {
        location
    }

    // MARK: Private

    private let location: ExternalRepositoryLocation?

}
