import DataAuthentication
import DataLearningProject
import InfrastructureNetworkClient

public struct LearningProjectRemoteAdapter: LearningProjectRemote {

    // MARK: Lifecycle

    public init(
        httpClient: HTTPClient,
        sessionStorage: LoginSessionStorage,
    ) {
        self.httpClient = httpClient
        self.sessionStorage = sessionStorage
    }

    // MARK: Public

    public func registerProject(_ request: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO {
        try await send(
            HTTPRequest(method: .post, path: "/api/v1/projects", headers: try await authorizationHeaders()),
            body: request,
            expecting: RegisterProjectResponseDTO.self,
        )
    }

    public func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> ProjectListResponseDTO {
        try await send(
            HTTPRequest(
                method: .get,
                path: "/api/v1/projects",
                queryItems: [
                    HTTPRequest.QueryItem(name: "page", value: String(page)),
                    HTTPRequest.QueryItem(name: "size", value: String(size)),
                ],
                headers: try await authorizationHeaders(),
            ),
            expecting: ProjectListResponseDTO.self,
        )
    }

    public func fetchProjectDetail(projectId: String) async throws -> ProjectDetailResponseDTO {
        try await send(
            HTTPRequest(
                method: .get,
                path: "/api/v1/projects/\(projectId)",
                headers: try await authorizationHeaders(),
            ),
            expecting: ProjectDetailResponseDTO.self,
        )
    }

    public func deleteProject(projectId: String) async throws {
        let request = HTTPRequest(
            method: .delete,
            path: "/api/v1/projects/\(projectId)",
            headers: try await authorizationHeaders(),
        )
        let response: HTTPResponse<APIEnvelope<EmptyPayload>>

        do {
            response = try await httpClient.send(request, expecting: APIEnvelope<EmptyPayload>.self)
        } catch {
            throw DataLearningProjectError.unexpected
        }

        switch response.body {
        case .decoded:
            return

        case .raw:
            throw mappedError(forStatusCode: response.statusCode)
        }
    }

    // MARK: Private

    private struct APIEnvelope<Payload: Decodable & Sendable>: Decodable, Sendable {
        let data: Payload?
    }

    private struct EmptyPayload: Decodable, Sendable { }

    private let httpClient: HTTPClient
    private let sessionStorage: LoginSessionStorage

    private func authorizationHeaders() async throws -> HTTPHeaders {
        guard let accessToken = try? await sessionStorage.load()?.accessToken
        else {
            return [:]
        }
        return ["Authorization": "Bearer \(accessToken)"]
    }

    private func mappedError(forStatusCode statusCode: Int) -> DataLearningProjectError {
        switch statusCode {
        case 400: .invalidRequest
        case 401: .unauthorized
        case 404: .notFound
        case 500: .serverError
        default: .unexpected
        }
    }

    private func send<Payload: Decodable & Sendable>(
        _ request: HTTPRequest,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        let response: HTTPResponse<APIEnvelope<Payload>>

        do {
            response = try await httpClient.send(request, expecting: APIEnvelope<Payload>.self)
        } catch {
            throw DataLearningProjectError.unexpected
        }

        switch response.body {
        case .decoded(let envelope):
            guard let payload = envelope.data
            else {
                throw DataLearningProjectError.unexpected
            }
            return payload

        case .raw:
            throw mappedError(forStatusCode: response.statusCode)
        }
    }

    private func send<Payload: Decodable & Sendable>(
        _ request: HTTPRequest,
        body: some Encodable & Sendable,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        let response: HTTPResponse<APIEnvelope<Payload>>

        do {
            response = try await httpClient.send(request, body: body, expecting: APIEnvelope<Payload>.self)
        } catch {
            throw DataLearningProjectError.unexpected
        }

        switch response.body {
        case .decoded(let envelope):
            guard let payload = envelope.data
            else {
                throw DataLearningProjectError.unexpected
            }
            return payload

        case .raw:
            throw mappedError(forStatusCode: response.statusCode)
        }
    }

}
