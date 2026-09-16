import CompositionShared
import DataExternalRepository
import DomainLearningProject
import Foundation
import InfrastructureNetworkClient

// MARK: - ExternalRepositoryAssembly

public struct ExternalRepositoryAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        transport: (any HTTPTransport)? = nil,
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
    ) {
        let client = makeHTTPClient(baseURL: baseURL, responseTimeout: responseTimeout, transport: transport)
        let lookup = ExternalRepositoryLookupAdapter(remote: ExternalRepositoryRemote(client: client))

        let locator = ExternalRepositoryLocatorAdapter(parser: GitHubRepositoryURLParser())
        self.locator = locator

        fetchExternalRepository = FetchExternalRepository(lookup: lookup, locator: locator)
    }

    // MARK: Public

    public let fetchExternalRepository: any FetchExternalRepositoryUseCase

    public let locator: any ExternalRepositoryLocator

}
