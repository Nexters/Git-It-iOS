import DataShared
import Foundation
import InfrastructureNetworkClient

// MARK: - MemberRemote

public struct MemberRemote: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        transport: (any RequestTransport)?,
        responseTimeout: Duration,
        credential: @escaping @Sendable () async -> RequestCredential,
        credentialRejected: @escaping @Sendable () async -> Void,
    ) {
        self.init(
            client: RequestClientFactory.makeClient(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
            ),
            credential: credential,
            credentialRejected: credentialRejected,
        )
    }

    init(
        client: HTTPClient,
        credential: @escaping @Sendable () async -> RequestCredential,
        credentialRejected: @escaping @Sendable () async -> Void,
    ) {
        self.client = client
        self.credential = credential
        self.credentialRejected = credentialRejected
    }

    // MARK: Public

    public func fetchProfile() async throws -> MemberProfileResponseDTO {
        try await send(
            .fetchProfile,
            expecting: MemberProfileResponseDTO.self,
        )
    }

    public func registerDeviceInfo(_ request: DeviceInfoRequestDTO) async throws {
        _ = try await send(
            .registerDeviceInfo,
            body: request,
            expecting: EmptyResponseData.self,
        )
    }

    public func curateMember(_ request: CurationRequestDTO) async throws {
        _ = try await send(
            .curateMember,
            body: request,
            expecting: EmptyResponseData.self,
        )
    }

    public func updatePosition(_ request: PositionRequestDTO) async throws {
        _ = try await send(
            .updatePosition,
            body: request,
            expecting: EmptyResponseData.self,
        )
    }

    public func updateCareerLevel(_ request: CareerLevelRequestDTO) async throws {
        _ = try await send(
            .updateCareerLevel,
            body: request,
            expecting: EmptyResponseData.self,
        )
    }

    public func withdrawMember() async throws {
        _ = try await send(
            .withdrawMember,
            expecting: EmptyResponseData.self,
        )
    }

    // MARK: Private

    private let client: HTTPClient
    private let credential: @Sendable () async -> RequestCredential
    private let credentialRejected: @Sendable () async -> Void

    private func send<Payload: Decodable & Sendable>(
        _ endpoint: MemberEndpoint,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        do {
            let response = try await client.send(
                try await httpRequest(for: endpoint),
                expecting: APIResponseDTO<Payload>.self,
            )
            return try await payload(from: response)
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    private func send<Payload: Decodable & Sendable>(
        _ endpoint: MemberEndpoint,
        body: some Encodable & Sendable,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        do {
            let response = try await client.send(
                try await httpRequest(for: endpoint),
                body: body,
                expecting: APIResponseDTO<Payload>.self,
            )
            return try await payload(from: response)
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    private func httpRequest(for endpoint: MemberEndpoint) async throws -> HTTPRequest {
        switch await credential() {
        case .available(let accessToken):
            return HTTPRequest(
                method: endpoint.transportMethod,
                path: endpoint.path,
                headers: endpoint.headers(accessToken: accessToken),
            )

        case .signedOut:
            throw MemberServiceError.unauthorized
        }
    }

    private func payload<Payload: Decodable & Sendable>(
        from response: HTTPResponse<APIResponseDTO<Payload>>
    ) async throws -> Payload {
        switch response.body {
        case .decoded(let envelope):
            if let payload = envelope.data {
                return payload
            }
            if let empty = EmptyResponseData() as? Payload {
                return empty
            }
            throw MemberServiceError.unexpectedStatus

        case .raw(let data):
            let error = MemberServiceError(from: try serverError(
                statusCode: response.statusCode,
                data: data,
            ))
            if error == .unauthorized {
                await credentialRejected()
            }
            throw error

        @unknown default:
            throw MemberServiceError.unexpectedStatus
        }
    }

    private func serverError(
        statusCode: Int,
        data: Data,
    ) throws -> ServerAPIError {
        do {
            let envelope = try JSONDecoder().decode(
                APIResponseDTO<EmptyResponseData>.self,
                from: data,
            )
            return ServerAPIError(
                httpStatus: statusCode,
                code: envelope.code,
                message: envelope.message,
                fieldErrors: envelope.errors,
            )
        } catch {
            throw MemberServiceError.unexpectedStatus
        }
    }

    private func dataError(for error: HTTPClientError) throws -> MemberServiceError {
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
