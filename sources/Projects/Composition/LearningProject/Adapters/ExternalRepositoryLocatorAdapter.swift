import DataExternalRepository
import DomainLearningProject

// MARK: - ExternalRepositoryLocatorAdapter

struct ExternalRepositoryLocatorAdapter: DomainLearningProject.ExternalRepositoryLocator {

    // MARK: Lifecycle

    init(parser: GitHubRepositoryURLParser) {
        self.parser = parser
    }

    // MARK: Internal

    func location(from url: String) -> DomainLearningProject.ExternalRepositoryLocation? {
        parser.location(from: url).map {
            DomainLearningProject.ExternalRepositoryLocation(owner: $0.owner, name: $0.name)
        }
    }

    // MARK: Private

    private let parser: GitHubRepositoryURLParser

}
