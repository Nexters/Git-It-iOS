// MARK: - ExternalRepositoryLocation

public struct ExternalRepositoryLocation: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        owner: String,
        name: String,
    ) {
        self.owner = owner
        self.name = name
    }

    // MARK: Public

    public let owner: String
    public let name: String

}
