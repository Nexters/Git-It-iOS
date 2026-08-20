import DataLearningProject
import InfrastructureNetworkClient

public struct ExternalRepositoryRemoteAdapter: ExternalRepositoryRemote {

    // MARK: Lifecycle

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    // MARK: Public

    public func repository(
        owner: String,
        name: String,
    ) async throws -> GitHubRepositoryResponseDTO {
        let request = HTTPRequest(method: .get, path: "/repos/\(owner)/\(name)")
        let response: HTTPResponse<GitHubRepositoryResponseDTO>

        do {
            response = try await httpClient.send(request, expecting: GitHubRepositoryResponseDTO.self)
        } catch HTTPClientError.connectionFailed {
            throw DataExternalRepositoryError.offline
        } catch {
            throw DataExternalRepositoryError.other
        }

        switch response.body {
        case .decoded(let dto):
            return dto

        case .raw:
            throw DataExternalRepositoryError.other
        }
    }

    // MARK: Private

    private let httpClient: HTTPClient

}
