import Foundation
import InfrastructureNetworkClient

func makeHTTPClient(
    baseURL: URL,
    responseTimeout: Duration,
    transport: (any HTTPTransport)?,
) -> HTTPClient {
    if let transport {
        return HTTPClient(
            baseURL: baseURL,
            bodyCoding: StandardJSONBodyCoding(),
            responseTimeout: responseTimeout,
            transport: transport,
        )
    }
    return HTTPClient(
        baseURL: baseURL,
        bodyCoding: StandardJSONBodyCoding(),
        responseTimeout: responseTimeout,
    )
}
