import DomainIdentifier

public struct QuizBookmarkProject: Equatable, Identifiable, Sendable {

    // MARK: Lifecycle

    public init(
        id: ProjectID,
        name: String,
    ) {
        self.id = id
        self.name = name
    }

    // MARK: Public

    public let id: ProjectID
    public let name: String

}
