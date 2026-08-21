// MARK: - ProjectDetailResponseDTO

public struct ProjectDetailResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        repositoryURL: String,
        repositoryName: String,
        repositoryImageURL: String?,
        starCount: Int,
        techStack: [String],
        overallProgressPercent: Int,
        nextQuestionID: String?,
        sets: [ProjectSetSummaryDTO],
    ) {
        self.projectID = projectID
        self.repositoryURL = repositoryURL
        self.repositoryName = repositoryName
        self.repositoryImageURL = repositoryImageURL
        self.starCount = starCount
        self.techStack = techStack
        self.overallProgressPercent = overallProgressPercent
        self.nextQuestionID = nextQuestionID
        self.sets = sets
    }

    // MARK: Public

    public let projectID: String
    public let repositoryURL: String
    public let repositoryName: String
    public let repositoryImageURL: String?
    public let starCount: Int
    public let techStack: [String]
    public let overallProgressPercent: Int
    public let nextQuestionID: String?
    public let sets: [ProjectSetSummaryDTO]

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case projectID = "projectId"
        case repositoryURL = "repositoryUrl"
        case repositoryName
        case repositoryImageURL = "repositoryImageUrl"
        case starCount
        case techStack
        case overallProgressPercent
        case nextQuestionID = "nextQuestionId"
        case sets
    }

}

// MARK: - ProjectSetSummaryDTO

public struct ProjectSetSummaryDTO: Decodable, Equatable, Sendable {
    public init(
        setID: String,
        label: String,
        title: String,
    ) {
        self.setID = setID
        self.label = label
        self.title = title
    }

    public let setID: String
    public let label: String
    public let title: String

    private enum CodingKeys: String, CodingKey {
        case setID = "setId"
        case label
        case title
    }
}
