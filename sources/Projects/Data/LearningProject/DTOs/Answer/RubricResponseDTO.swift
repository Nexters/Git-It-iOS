public struct RubricResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        score: Int,
        feedback: String,
    ) {
        self.init(
            criteria: [RubricCriterionResponseDTO(text: feedback, points: score)],
            keyPoints: [],
            fullMarkExample: "",
            partialExample: "",
            zeroExample: "",
        )
    }

    public init(
        criteria: [RubricCriterionResponseDTO],
        keyPoints: [String],
        fullMarkExample: String,
        partialExample: String,
        zeroExample: String,
    ) {
        self.criteria = criteria
        self.keyPoints = keyPoints
        self.fullMarkExample = fullMarkExample
        self.partialExample = partialExample
        self.zeroExample = zeroExample
    }

    // MARK: Public

    public let criteria: [RubricCriterionResponseDTO]
    public let keyPoints: [String]
    public let fullMarkExample: String
    public let partialExample: String
    public let zeroExample: String

    public var feedback: String {
        criteria.map(\.text).joined(separator: "\n")
    }

}
