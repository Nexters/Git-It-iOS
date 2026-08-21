// MARK: - APIResponseDTO

public struct APIResponseDTO<Payload: Decodable & Sendable>: Decodable, Sendable {
    public let success: Bool
    public let data: Payload?
    public let code: String?
    public let message: String?
    public let errors: [FieldErrorDTO]?
}

// MARK: - FieldErrorDTO

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
