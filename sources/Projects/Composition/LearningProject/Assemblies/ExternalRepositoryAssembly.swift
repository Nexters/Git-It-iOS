import DataExternalRepository
import DataShared
import DomainExternalRepository
import Foundation

// MARK: - ExternalRepositoryAssembly

public struct ExternalRepositoryAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        transport: (any RequestTransport)? = nil,
        responseTimeout: Duration = RequestClientFactory.defaultResponseTimeout,
    ) {
        let locator = ExternalRepositoryLocatorAdapter(parser: GitHubRepositoryURLParser())
        self.locator = locator

        externalRepository = ExternalRepositoryResolver(
            lookup: ExternalRepositoryLookupAdapter(
                remote: ExternalRepositoryRemote(
                    baseURL: baseURL,
                    transport: transport,
                    responseTimeout: responseTimeout,
                )
            ),
            locator: locator,
        )
    }

    // MARK: Public

    public let externalRepository: any ExternalRepositoryUseCase

    public let locator: any ExternalRepositoryLocator

}
