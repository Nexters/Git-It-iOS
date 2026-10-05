public struct ChoiceSubmission: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        selectedIndex: Int,
        isCorrect: Bool,
    ) {
        self.selectedIndex = selectedIndex
        self.isCorrect = isCorrect
    }

    // MARK: Public

    public let selectedIndex: Int
    public let isCorrect: Bool

}
