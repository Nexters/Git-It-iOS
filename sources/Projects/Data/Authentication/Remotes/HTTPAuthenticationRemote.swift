import Foundation
import InfrastructureNetworkClient

// MARK: - HTTPAuthenticationRemote

public struct HTTPAuthenticationRemote: AuthenticationRemote {

    // MARK: Lifecycle

    public init(
        client: HTTPClient,
        accessTokenProvider: @escaping @Sendable () async -> String?,
    ) {
        self.client = client
        self.accessTokenProvider = accessTokenProvider
    }

    // MARK: Public

    public func appleLogin(idToken: String) async throws -> LoginResponseDTO {
        try await send(
            .appleLogin,
            body: AppleLoginRequestDTO(idToken: idToken),
            accessToken: nil,
            expecting: LoginResponseDTO.self,
        )
    }

    public func verifyAccessToken() async throws {
        _ = try await send(
            .verifyAccessToken,
            accessToken: await accessTokenProvider(),
            expecting: EmptyResponseData.self,
        )
    }

    // MARK: Private

    private let client: HTTPClient
    private let accessTokenProvider: @Sendable () async -> String?

    private func send<Payload: Decodable & Sendable>(
        _ endpoint: AuthenticationEndpoint,
        accessToken: String?,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        do {
            let response = try await client.send(
                httpRequest(for: endpoint, accessToken: accessToken),
                expecting: APIResponseDTO<Payload>.self,
            )
            return try payload(from: response)
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    private func send<Payload: Decodable & Sendable>(
        _ endpoint: AuthenticationEndpoint,
        body: some Encodable & Sendable,
        accessToken: String?,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        do {
            let response = try await client.send(
                httpRequest(for: endpoint, accessToken: accessToken),
                body: body,
                expecting: APIResponseDTO<Payload>.self,
            )
            return try payload(from: response)
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    private func httpRequest(
        for endpoint: AuthenticationEndpoint,
        accessToken: String?,
    ) -> HTTPRequest {
        var headers = HTTPHeaders()
        for (name, value) in endpoint.headers(accessToken: accessToken) {
            headers[name] = value
        }
        return HTTPRequest(
            method: endpoint.method == .get ? .get : .post,
            path: endpoint.path,
            headers: headers,
        )
    }

    private func payload<Payload: Decodable & Sendable>(
        from response: HTTPResponse<APIResponseDTO<Payload>>
    ) throws -> Payload {
        switch response.body {
        case .decoded(let envelope):
            guard let payload = envelope.data else { throw DataAuthenticationError.unexpectedStatus }
            return payload

        case .raw(let data):
            throw DataAuthenticationError(from: try serverError(statusCode: response.statusCode, data: data))

        @unknown default:
            throw DataAuthenticationError.unexpectedStatus
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
            throw DataAuthenticationError.decoding
        }
    }

    private func dataError(for error: HTTPClientError) throws -> DataAuthenticationError {
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
