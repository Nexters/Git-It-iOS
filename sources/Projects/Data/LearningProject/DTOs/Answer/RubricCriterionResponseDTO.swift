public struct RubricCriterionResponseDTO: Decodable, Equatable, Sendable {
    public init(
        text: String,
        points: Int,
    ) {
        self.text = text
        self.points = points
    }

    public let text: String
    public let points: Int
}
