import Foundation
import InfrastructureNetworkClient

// MARK: - RequestClientFactory

public enum RequestClientFactory {

    // MARK: Public

    public static let defaultResponseTimeout = HTTPClient.defaultResponseTimeout

    // MARK: Package

    package static func makeClient(
        baseURL: URL,
        transport: (any RequestTransport)?,
        responseTimeout: Duration,
    ) -> HTTPClient {
        guard let transport else {
            return HTTPClient(
                baseURL: baseURL,
                bodyCoding: StandardJSONBodyCoding(),
                responseTimeout: responseTimeout,
            )
        }
        return HTTPClient(
            baseURL: baseURL,
            bodyCoding: StandardJSONBodyCoding(),
            responseTimeout: responseTimeout,
            transport: RequestTransportBridge(transport: transport),
        )
    }

}
