import DataShared
import Foundation
import InfrastructureNetworkClient

// MARK: - AuthenticationRemote

public struct AuthenticationRemote: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        transport: (any RequestTransport)?,
        responseTimeout: Duration,
        credential: @escaping @Sendable () async -> RequestCredential,
    ) {
        self.init(
            client: RequestClientFactory.makeClient(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
            ),
            credential: credential,
        )
    }

    init(
        client: HTTPClient,
        credential: @escaping @Sendable () async -> RequestCredential,
    ) {
        self.client = client
        self.credential = credential
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
        guard case .available(let accessToken) = await credential() else {
            throw AuthenticationServiceError.unauthorized
        }
        _ = try await send(
            .verifyAccessToken,
            accessToken: accessToken,
            expecting: EmptyResponseData.self,
        )
    }

    // MARK: Private

    private let client: HTTPClient
    private let credential: @Sendable () async -> RequestCredential

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
        HTTPRequest(
            method: endpoint.transportMethod,
            path: endpoint.path,
            headers: endpoint.headers(accessToken: accessToken),
        )
    }

    private func payload<Payload: Decodable & Sendable>(
        from response: HTTPResponse<APIResponseDTO<Payload>>
    ) throws -> Payload {
        switch response.body {
        case .decoded(let envelope):
            if let payload = envelope.data {
                return payload
            }
            if let empty = EmptyResponseData() as? Payload {
                return empty
            }
            throw AuthenticationServiceError.unexpectedStatus

        case .raw(let data):
            throw AuthenticationServiceError(from: try serverError(statusCode: response.statusCode, data: data))

        @unknown default:
            throw AuthenticationServiceError.unexpectedStatus
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
            throw AuthenticationServiceError.unexpectedStatus
        }
    }

    private func dataError(for error: HTTPClientError) throws -> AuthenticationServiceError {
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
            return .unexpectedStatus

        @unknown default:
            return .unexpectedStatus
        }
    }

}
