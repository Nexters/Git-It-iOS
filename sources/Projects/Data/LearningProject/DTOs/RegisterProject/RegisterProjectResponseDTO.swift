public struct RegisterProjectResponseDTO: Decodable, Equatable, Sendable {
    public init(
        projectID: String,
        requestStatus: String,
    ) {
        self.projectID = projectID
        self.requestStatus = requestStatus
    }

    public let projectID: String
    public let requestStatus: String

    private enum CodingKeys: String, CodingKey {
        case projectID = "projectId"
        case requestStatus = "status"
    }
}
