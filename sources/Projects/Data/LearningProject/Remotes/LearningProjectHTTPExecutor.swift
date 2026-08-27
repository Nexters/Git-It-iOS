import Foundation
import InfrastructureNetworkClient

// MARK: - LearningProjectHTTPExecutor

struct LearningProjectHTTPExecutor: Sendable {

    // MARK: Internal

    let client: HTTPClient
    let accessTokenProvider: @Sendable () async -> String?

    func send<Payload: Decodable & Sendable>(
        _ request: LearningProjectRequest,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        do {
            let response = try await client.send(await httpRequest(for: request), expecting: APIResponseDTO<Payload>.self)
            return try payload(from: response)
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    func send<Payload: Decodable & Sendable>(
        _ request: LearningProjectRequest,
        body: some Encodable & Sendable,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        do {
            let response = try await client.send(
                await httpRequest(for: request),
                body: body,
                expecting: APIResponseDTO<Payload>.self,
            )
            return try payload(from: response)
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    // MARK: Private

    private func httpRequest(for request: LearningProjectRequest) async -> HTTPRequest {
        HTTPRequest(
            method: httpMethod(for: request.method),
            path: request.path,
            queryItems: request.queryItems.map { HTTPRequest.QueryItem(name: $0.key, value: $0.value) },
            headers: await authorizedHeaders(),
        )
    }

    private func authorizedHeaders() async -> HTTPHeaders {
        guard let accessToken = await accessTokenProvider() else { return [:] }
        var headers = HTTPHeaders()
        for (name, value) in AuthorizedRequestHeaders(accessToken: accessToken).fieldValues {
            headers[name] = value
        }
        return headers
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
