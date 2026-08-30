public struct SubmitChoiceAnswerRequestDTO: Encodable, Equatable, Sendable {
    public init(selectedIndex: Int) {
        self.selectedIndex = selectedIndex
    }

    public let selectedIndex: Int
}
