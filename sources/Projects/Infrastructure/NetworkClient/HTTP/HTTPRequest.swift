// MARK: - HTTPRequest

public struct HTTPRequest: Sendable {

    // MARK: Lifecycle

    public init(
        method: HTTPMethod,
        path: String,
        queryItems: [QueryItem] = [],
        headers: HTTPHeaders = [:],
        responseTimeout: Duration? = nil,
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.responseTimeout = responseTimeout
    }

    // MARK: Public

    public var method: HTTPMethod
    public var path: String
    public var queryItems: [QueryItem]
    public var headers: HTTPHeaders
    public var responseTimeout: Duration?
}
