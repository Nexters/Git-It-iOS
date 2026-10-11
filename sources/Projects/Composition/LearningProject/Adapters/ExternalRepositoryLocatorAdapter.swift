import DataExternalRepository
import DomainUseCaseDependency
import DomainUseCaseInterface

// MARK: - ExternalRepositoryLocatorAdapter

public struct ExternalRepositoryLocatorAdapter: DomainUseCaseDependency.ExternalRepositoryLocator {

    // MARK: Lifecycle

    public init(parser: GitHubRepositoryURLParser) {
        self.parser = parser
    }

    // MARK: Public

    public func location(from url: ExternalRepositoryURL) -> DomainUseCaseInterface.ExternalRepositoryLocation? {
        parser.location(from: url).map {
            DomainUseCaseInterface.ExternalRepositoryLocation(
                owner: $0.owner,
                name: $0.name,
            )
        }
    }

    // MARK: Private

    private let parser: GitHubRepositoryURLParser

}
