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
        let lookup = ExternalRepositoryLookupAdapter(remote: HTTPExternalRepositoryRemote(client: client))

        fetchExternalRepository = FetchExternalRepository(lookup: lookup)
    }

    // MARK: Public

    public let fetchExternalRepository: any FetchExternalRepositoryUseCase

}
