public struct FieldErrorDTO: Decodable, Equatable, Sendable {
    public init(
        field: String,
        message: String?,
    ) {
        self.field = field
        self.message = message
    }

    public let field: String
    public let message: String?
}
