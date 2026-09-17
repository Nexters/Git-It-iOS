public struct EssaySubmission: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        text: String,
    ) {
        self.text = text
    }

    // MARK: Public

    public let text: String

}
