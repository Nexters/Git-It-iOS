import Foundation
import InfrastructureNetworkClient

/// Assembly가 공통으로 사용하는 `HTTPClient` 조립 지점입니다. `transport`가 주어지면(테스트의
/// stub transport 등) 그대로 사용하고, 없으면 `HTTPClient`의 기본 live transport를 사용한다.
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
