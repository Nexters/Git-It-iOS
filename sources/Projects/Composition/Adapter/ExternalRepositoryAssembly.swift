import DataExternalRepository
import DomainLearningProject
import Foundation
import InfrastructureNetworkClient

// MARK: - ExternalRepositoryAssembly

public struct ExternalRepositoryAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
    ) {
        let client = HTTPClient(
            baseURL: baseURL,
            bodyCoding: StandardJSONBodyCoding(),
            responseTimeout: responseTimeout,
        )
        let lookup = ExternalRepositoryLookupAdapter(remote: HTTPExternalRepositoryRemote(client: client))

        fetchExternalRepository = FetchExternalRepository(lookup: lookup)
    }

    // MARK: Public

    public let fetchExternalRepository: any FetchExternalRepositoryUseCase

}
