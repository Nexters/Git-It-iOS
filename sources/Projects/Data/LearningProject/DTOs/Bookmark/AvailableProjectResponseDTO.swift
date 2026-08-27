public struct AvailableProjectResponseDTO: Decodable, Equatable, Sendable {
    public init(
        projectID: String,
        repositoryName: String,
    ) {
        self.projectID = projectID
        self.repositoryName = repositoryName
    }

    public let projectID: String
    public let repositoryName: String

    private enum CodingKeys: String, CodingKey {
        case projectID = "projectId"
        case repositoryName = "projectName"
    }
}
