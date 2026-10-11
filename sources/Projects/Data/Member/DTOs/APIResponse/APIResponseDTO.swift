public struct APIResponseDTO<Payload: Decodable & Sendable>: Decodable, Sendable {
    public let success: Bool
    public let data: Payload?
    public let code: String?
    public let message: String?
    public let errors: [FieldErrorDTO]?
}
