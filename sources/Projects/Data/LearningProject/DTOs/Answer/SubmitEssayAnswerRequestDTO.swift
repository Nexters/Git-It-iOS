public struct SubmitEssayAnswerRequestDTO: Encodable, Equatable, Sendable {
    public init(text: String) {
        self.text = text
    }

    public let text: String
}
