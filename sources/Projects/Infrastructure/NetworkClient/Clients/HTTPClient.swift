import Foundation

// MARK: - HTTPClient

public struct HTTPClient: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        bodyCoding: any HTTPBodyCoding,
        commonHeaders: HTTPHeaders = [:],
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
        transport: any HTTPTransport,
    ) {
        self.baseURL = baseURL
        self.bodyCoding = bodyCoding
        self.commonHeaders = commonHeaders
        self.responseTimeout = responseTimeout
        self.transport = transport
    }

    public init(
        baseURL: URL,
        bodyCoding: any HTTPBodyCoding,
        commonHeaders: HTTPHeaders = [:],
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
    ) {
        self.init(
            baseURL: baseURL,
            bodyCoding: bodyCoding,
            commonHeaders: commonHeaders,
            responseTimeout: responseTimeout,
            transport: URLSessionTransport(),
        )
    }

    // MARK: Public

    public static let defaultResponseTimeout = Duration.seconds(15)

    public func send<ResponseBody: Decodable & Sendable>(
        _ request: HTTPRequest,
        expecting _: ResponseBody.Type,
    ) async throws(HTTPClientError) -> HTTPResponse<ResponseBody> {
        try await send(request, encodedBody: { nil }, expecting: ResponseBody.self)
    }

    public func send<ResponseBody: Decodable & Sendable>(
        _ request: HTTPRequest,
        body: some Encodable & Sendable,
        expecting _: ResponseBody.Type,
    ) async throws(HTTPClientError) -> HTTPResponse<ResponseBody> {
        try await send(
            request,
            encodedBody: { try bodyCoding.encode(body) },
            expecting: ResponseBody.self,
        )
    }

    // MARK: Private

    private let baseURL: URL
    private let bodyCoding: any HTTPBodyCoding
    private let commonHeaders: HTTPHeaders
    private let responseTimeout: Duration
    private let transport: any HTTPTransport
    private let urlBuilder = RequestURLBuilder()

    private func send<ResponseBody: Decodable & Sendable>(
        _ request: HTTPRequest,
        encodedBody: () throws -> Data?,
        expecting _: ResponseBody.Type,
    ) async throws(HTTPClientError) -> HTTPResponse<ResponseBody> {
        let requestURL = try urlBuilder.build(
            baseURL: baseURL,
            path: request.path,
            queryItems: request.queryItems,
        )
        let headers = commonHeaders.overridden(by: request.headers)
        let body: Data?
        do {
            body = try encodedBody()
        } catch {
            throw .requestEncodingFailed
        }

        let transportRequest = HTTPTransportRequest(
            url: requestURL,
            method: request.method,
            headers: headers,
            body: body,
            responseTimeout: request.responseTimeout ?? responseTimeout,
        )
        let transportResponse = try await send(transportRequest)

        if (200 ... 299).contains(transportResponse.statusCode) {
            do {
                return HTTPResponse(
                    statusCode: transportResponse.statusCode,
                    headers: transportResponse.headers,
                    body: .decoded(try bodyCoding.decode(ResponseBody.self, from: transportResponse.body)),
                )
            } catch {
                throw .responseDecodingFailed
            }
        }

        return HTTPResponse(
            statusCode: transportResponse.statusCode,
            headers: transportResponse.headers,
            body: .raw(transportResponse.body),
        )
    }

    private func send(_ request: HTTPTransportRequest) async throws(HTTPClientError) -> HTTPTransportResponse {
        do {
            return try await withThrowingTaskGroup(of: HTTPTransportResponse.self) { group in
                group.addTask {
                    try await transport.send(request)
                }
                group.addTask {
                    try await Task.sleep(for: request.responseTimeout)
                    try Task.checkCancellation()
                    throw HTTPClientError.timedOut
                }

                defer { group.cancelAll() }
                guard let response = try await group.next() else {
                    throw HTTPClientError.connectionFailed
                }
                return response
            }
        } catch {
            if Task.isCancelled {
                throw .cancelled
            }
            guard let clientError = error as? HTTPClientError else {
                throw .connectionFailed
            }
            if clientError == .timedOut {
                await Task.yield()
                if Task.isCancelled {
                    throw .cancelled
                }
            }
            throw clientError
        }
    }

}
