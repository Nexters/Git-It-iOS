import InfrastructureNetworkClient

// MARK: - HTTPExternalRepositoryRemote

public struct HTTPExternalRepositoryRemote: ExternalRepositoryRemote {

    // MARK: Lifecycle

    public init(client: HTTPClient) {
        self.client = client
    }

    // MARK: Public

    public func repository(_ request: GitHubRepositoryRequest) async throws -> GitHubRepositoryResponseDTO {
        var headers = HTTPHeaders()
        for (name, value) in request.headers {
            headers[name] = value
        }
        let httpRequest = HTTPRequest(method: .get, path: request.path, headers: headers)

        do {
            let response = try await client.send(httpRequest, expecting: GitHubRepositoryResponseDTO.self)
            switch response.body {
            case .decoded(let dto):
                return dto

            case .raw:
                throw DataExternalRepositoryError.other

            @unknown default:
                throw DataExternalRepositoryError.other
            }
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    // MARK: Private

    private let client: HTTPClient

    private func dataError(for error: HTTPClientError) throws -> DataExternalRepositoryError {
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
