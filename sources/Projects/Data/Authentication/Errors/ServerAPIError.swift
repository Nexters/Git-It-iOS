public struct ServerAPIError: Equatable, Error, Sendable {
    public init(httpStatus: Int, code: String?, message: String?, fieldErrors: [FieldErrorDTO]?) {
        self.httpStatus = httpStatus
        self.code = code
        self.message = message
        self.fieldErrors = fieldErrors
    }

    public let httpStatus: Int
    public let code: String?
    public let message: String?
    public let fieldErrors: [FieldErrorDTO]?
}
