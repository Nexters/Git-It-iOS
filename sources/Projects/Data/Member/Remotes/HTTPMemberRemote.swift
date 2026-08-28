import Foundation
import InfrastructureNetworkClient

// MARK: - HTTPMemberRemote

public struct HTTPMemberRemote: MemberRemote {

    // MARK: Lifecycle

    public init(
        client: HTTPClient,
        accessTokenProvider: @escaping @Sendable () async -> String?,
    ) {
        self.client = client
        self.accessTokenProvider = accessTokenProvider
    }

    // MARK: Public

    public func fetchProfile() async throws -> MemberProfileResponseDTO {
        try await send(.fetchProfile, expecting: MemberProfileResponseDTO.self)
    }

    public func registerDeviceInfo(_ request: DeviceInfoRequestDTO) async throws {
        _ = try await send(.registerDeviceInfo, body: request, expecting: EmptyResponseData.self)
    }

    public func curateMember(_ request: CurationRequestDTO) async throws {
        _ = try await send(.curateMember, body: request, expecting: EmptyResponseData.self)
    }

    public func updatePosition(_ request: PositionRequestDTO) async throws {
        _ = try await send(.updatePosition, body: request, expecting: EmptyResponseData.self)
    }

    public func updateCareerLevel(_ request: CareerLevelRequestDTO) async throws {
        _ = try await send(.updateCareerLevel, body: request, expecting: EmptyResponseData.self)
    }

    public func withdrawMember() async throws {
        _ = try await send(.withdrawMember, expecting: EmptyResponseData.self)
    }

    // MARK: Private

    private let client: HTTPClient
    private let accessTokenProvider: @Sendable () async -> String?

    private func send<Payload: Decodable & Sendable>(
        _ endpoint: MemberEndpoint,
        expecting _: Payload.Type,
    ) async throws -> Payload {
        do {
            let response = try await client.send(await httpRequest(for: endpoint), expecting: APIResponseDTO<Payload>.self)
            return try payload(from: response)
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
                await httpRequest(for: endpoint),
                body: body,
                expecting: APIResponseDTO<Payload>.self,
            )
            return try payload(from: response)
        } catch let error as HTTPClientError {
            throw try dataError(for: error)
        }
    }

    private func httpRequest(for endpoint: MemberEndpoint) async -> HTTPRequest {
        var headers = HTTPHeaders()
        if let accessToken = await accessTokenProvider() {
            for (name, value) in endpoint.headers(accessToken: accessToken) {
                headers[name] = value
            }
        }
        return HTTPRequest(method: httpMethod(for: endpoint.method), path: endpoint.path, headers: headers)
    }

    private func httpMethod(for method: MemberEndpoint.Method) -> InfrastructureNetworkClient.HTTPMethod {
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
            if let payload = envelope.data {
                return payload
            }
            if let empty = EmptyResponseData() as? Payload {
                return empty
            }
            throw DataMemberError.unexpectedStatus

        case .raw(let data):
            throw DataMemberError(from: try serverError(statusCode: response.statusCode, data: data))

        @unknown default:
            throw DataMemberError.unexpectedStatus
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
            throw DataMemberError.decoding
        }
    }

    private func dataError(for error: HTTPClientError) throws -> DataMemberError {
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
