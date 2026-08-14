// MARK: - HTTPResponse

public struct HTTPResponse<Value: Sendable>: Sendable {

    // MARK: Internal

    init(statusCode: Int, headers: HTTPHeaders, body: Body) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }

    // MARK: Public

    public let statusCode: Int
    public let headers: HTTPHeaders
    public let body: Body
}
