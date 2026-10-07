public struct ProjectSetLabel: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        label: String,
        title: String,
    ) {
        self.label = label
        self.title = title
    }

    // MARK: Public

    public let label: String
    public let title: String

}
