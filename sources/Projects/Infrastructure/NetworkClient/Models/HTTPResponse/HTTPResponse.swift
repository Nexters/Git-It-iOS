// MARK: - HTTPResponse

public struct HTTPResponse<Value: Sendable>: Sendable {

    // MARK: Public

    public let statusCode: Int
    public let headers: HTTPHeaders
    public let body: Body

}
