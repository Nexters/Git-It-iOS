import Foundation
import InfrastructureNetworkClient

// MARK: - HTTPProjectRemote

public struct HTTPProjectRemote: ProjectRemote {

    // MARK: Lifecycle

    public init(client: HTTPClient) {
        self.client = client
    }

    // MARK: Public

    public func registerProject(_ request: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO {
        try await send(
            LearningProjectRequest(method: .post, path: LearningProjectRequest.basePath),
            body: request,
            expecting: RegisterProjectResponseDTO.self,
        )
    }

    public func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> ProjectListResponseDTO {
        try await send(
            LearningProjectRequest(
                method: .get,
                path: LearningProjectRequest.basePath,
                queryItems: ["page": String(page), "size": String(size)],
            ),
            expecting: ProjectListResponseDTO.self,
        )
    }

    public func fetchProjectDetail(projectID: String) async throws -> ProjectDetailResponseDTO {
        try await send(
            LearningProjectRequest(method: .get, path: "\(LearningProjectRequest.basePath)/\(projectID)"),
            expecting: ProjectDetailResponseDTO.self,
        )
    }

    public func deleteProject(projectID: String) async throws {
        _ = try await send(
            LearningProjectRequest(method: .delete, path: "\(LearningProjectRequest.basePath)/\(projectID)"),
            expecting: EmptyResponseData.self,
        )
    }

    // MARK: Private

    private let client: HTTPClient

    private func send<Payload: Decodable & Sendable>(
        _ request: LearningProjectRequest,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        try await send(httpRequest(for: request), expecting: Payload.self)
    }

    private func send<Payload: Decodable & Sendable>(
        _ request: LearningProjectRequest,
        body: some Encodable & Sendable,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        try await send(httpRequest(for: request), body: body, expecting: Payload.self)
    }

    private func send<Payload: Decodable & Sendable>(
        _ httpRequest: HTTPRequest,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        do {
            let response = try await client.send(httpRequest, expecting: APIResponseDTO<Payload>.self)
            return try payload(from: response)
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    private func send<Payload: Decodable & Sendable>(
        _ httpRequest: HTTPRequest,
        body: some Encodable & Sendable,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        do {
            let response = try await client.send(httpRequest, body: body, expecting: APIResponseDTO<Payload>.self)
            return try payload(from: response)
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    private func httpRequest(for request: LearningProjectRequest) -> HTTPRequest {
        HTTPRequest(
            method: httpMethod(for: request.method),
            path: request.path,
            queryItems: request.queryItems.map { HTTPRequest.QueryItem(name: $0.key, value: $0.value) },
        )
    }

    private func httpMethod(for method: HTTPMethod) -> InfrastructureNetworkClient.HTTPMethod {
        switch method {
        case .get: .get
        case .post: .post
        case .delete: .delete
        }
    }

    private func payload<Payload: Decodable & Sendable>(
        from response: HTTPResponse<APIResponseDTO<Payload>>
    ) throws -> Payload {
        switch response.body {
        case .decoded(let envelope):
            guard let payload = envelope.data else { throw DataLearningProjectError.unexpectedStatus }
            return payload

        case .raw(let data):
            throw DataLearningProjectError(from: try serverError(statusCode: response.statusCode, data: data))

        @unknown default:
            throw DataLearningProjectError.unexpectedStatus
        }
    }

    private func serverError(
        statusCode: Int,
        data: Data,
    ) throws -> ServerAPIError {
        do {
            let envelope = try JSONDecoder().decode(APIResponseDTO<EmptyResponseData>.self, from: data)
            return ServerAPIError(
                httpStatus: statusCode,
                code: envelope.code,
                message: envelope.message,
                fieldErrors: envelope.errors,
            )
        } catch {
            throw DataLearningProjectError.decoding
        }
    }

    private func dataError(for error: HTTPClientError) throws -> DataLearningProjectError {
        switch error {
        case .cancelled:
            throw CancellationError()

        case .invalidURL,
             .requestEncodingFailed:
            return .invalidRequest

        case .connectionFailed,
             .timedOut:
            return .transport

        case .responseDecodingFailed:
            return .decoding

        @unknown default:
            return .unexpectedStatus
        }
    }

}

// MARK: - EmptyResponseData

struct EmptyResponseData: Decodable, Sendable { }
