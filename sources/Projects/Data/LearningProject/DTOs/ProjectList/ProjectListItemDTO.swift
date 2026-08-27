public struct ProjectListItemDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        repositoryName: String,
        repositoryImageURL: String?,
        techStack: [String],
        currentSetLabel: String,
        currentSetTitle: String,
        nextSetID: String?,
        nextQuestionID: String?,
        overallProgressPercent: Int,
    ) {
        self.projectID = projectID
        self.repositoryName = repositoryName
        self.repositoryImageURL = repositoryImageURL
        self.techStack = techStack
        self.currentSetLabel = currentSetLabel
        self.currentSetTitle = currentSetTitle
        self.nextSetID = nextSetID
        self.nextQuestionID = nextQuestionID
        self.overallProgressPercent = overallProgressPercent
    }

    // MARK: Public

    public let projectID: String
    public let repositoryName: String
    public let repositoryImageURL: String?
    public let techStack: [String]
    public let currentSetLabel: String
    public let currentSetTitle: String
    public let nextSetID: String?
    public let nextQuestionID: String?
    public let overallProgressPercent: Int

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case projectID = "projectId"
        case repositoryName
        case repositoryImageURL = "repositoryImageUrl"
        case techStack
        case currentSetLabel
        case currentSetTitle
        case nextSetID = "nextSetId"
        case nextQuestionID = "nextQuestionId"
        case overallProgressPercent
    }

}
