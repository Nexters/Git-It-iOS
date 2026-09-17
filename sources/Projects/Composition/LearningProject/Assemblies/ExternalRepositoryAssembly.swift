import DataExternalRepository
import DataShared
import DomainLearningProject
import Foundation

// MARK: - ExternalRepositoryAssembly

public struct ExternalRepositoryAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        transport: (any RequestTransport)? = nil,
        responseTimeout: Duration = RequestClientFactory.defaultResponseTimeout,
    ) {
        let lookup = ExternalRepositoryLookupAdapter(
            remote: ExternalRepositoryRemote(baseURL: baseURL, transport: transport, responseTimeout: responseTimeout)
        )

        let locator = ExternalRepositoryLocatorAdapter(parser: GitHubRepositoryURLParser())
        self.locator = locator

        fetchExternalRepository = FetchExternalRepository(lookup: lookup, locator: locator)
    }

    // MARK: Public

    public let fetchExternalRepository: any FetchExternalRepositoryUseCase

    public let locator: any ExternalRepositoryLocator

}
