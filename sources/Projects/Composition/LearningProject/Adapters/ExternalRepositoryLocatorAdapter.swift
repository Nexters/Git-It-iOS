import DataExternalRepository
import DomainExternalRepository
import DomainIdentifier

// MARK: - ExternalRepositoryLocatorAdapter

public struct ExternalRepositoryLocatorAdapter: DomainExternalRepository.ExternalRepositoryLocator {

    // MARK: Lifecycle

    public init(parser: GitHubRepositoryURLParser) {
        self.parser = parser
    }

    // MARK: Public

    public func location(from url: ExternalRepositoryURL) -> DomainExternalRepository.ExternalRepositoryLocation? {
        parser.location(from: url).map {
            DomainExternalRepository.ExternalRepositoryLocation(
                owner: $0.owner,
                name: $0.name,
            )
        }
    }

    // MARK: Private

    private let parser: GitHubRepositoryURLParser

}
