import DataShared
import Foundation
import InfrastructureNetworkClient

// MARK: - ExternalRepositoryRemote

public struct ExternalRepositoryRemote: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        transport: (any RequestTransport)?,
        responseTimeout: Duration,
    ) {
        self.init(
            client: RequestClientFactory.makeClient(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
            )
        )
    }

    init(client: HTTPClient) {
        self.client = client
    }

    // MARK: Public

    public func repository(_ request: GitHubRepositoryRequest) async throws -> GitHubRepositoryResponseDTO {
        var headers = HTTPHeaders()
        for (name, value) in request.headers {
            headers[name] = value
        }
        let httpRequest = HTTPRequest(
            method: .get,
            path: request.path,
            headers: headers,
        )

        do {
            let response = try await client.send(
                httpRequest,
                expecting: GitHubRepositoryResponseDTO.self,
            )
            switch response.body {
            case .decoded(let dto):
                return dto

            case .raw:
                throw ExternalRepositoryFetchError.other

            @unknown default:
                throw ExternalRepositoryFetchError.other
            }
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    // MARK: Private

    private let client: HTTPClient

    private func dataError(for error: HTTPClientError) throws -> ExternalRepositoryFetchError {
        switch error {
        case .cancelled:
            throw CancellationError()

        case .connectionFailed,
             .timedOut:
            return .offline

        case .invalidURL,
             .requestEncodingFailed,
             .responseDecodingFailed:
            return .other

        @unknown default:
            return .other
        }
    }

}
