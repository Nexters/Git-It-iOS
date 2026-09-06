public struct SubmittedAnswer: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        selectedIndex: Int?,
        text: String?,
        correct: Bool?,
    ) {
        self.selectedIndex = selectedIndex
        self.text = text
        self.correct = correct
    }

    // MARK: Public

    public let selectedIndex: Int?
    public let text: String?
    public let correct: Bool?

}
