public struct QuizGenerationStatusResponseDTO: Decodable, Equatable, Sendable {
    public init(status: String) {
        self.status = status
    }

    public let status: String
}
