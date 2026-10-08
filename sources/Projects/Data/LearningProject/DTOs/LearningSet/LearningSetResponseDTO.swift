import Foundation

public struct LearningSetResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        setID: String,
        title: String,
        description: String,
        orientation: String,
        level: String,
        questions: [QuestionResponseDTO],
    ) {
        self.setID = setID
        self.title = title
        self.description = description
        self.orientation = orientation
        self.level = level
        self.questions = questions
    }

    // MARK: Public

    public let setID: String
    public let title: String
    public let description: String
    public let orientation: String
    public let level: String
    public let questions: [QuestionResponseDTO]

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case setID = "setId"
        case title
        case description
        case orientation
        case level
        case questions
    }

}
