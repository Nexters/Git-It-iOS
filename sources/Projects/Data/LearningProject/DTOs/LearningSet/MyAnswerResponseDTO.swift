import Foundation

public struct MyAnswerResponseDTO: Decodable, Equatable, Sendable {
    public init(
        selectedIndex: Int?,
        text: String?,
        correct: Bool?,
        answeredAt: Date,
    ) {
        self.selectedIndex = selectedIndex
        self.text = text
        self.correct = correct
        self.answeredAt = answeredAt
    }

    public let selectedIndex: Int?
    public let text: String?
    public let correct: Bool?
    public let answeredAt: Date
}
