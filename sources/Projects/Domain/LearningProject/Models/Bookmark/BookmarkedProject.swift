public struct BookmarkedProject: Equatable, Sendable, Identifiable {

    // MARK: Lifecycle

    public init(
        id: String,
        name: String,
    ) {
        self.id = id
        self.name = name
    }

    // MARK: Public

    public let id: String
    public let name: String

}
