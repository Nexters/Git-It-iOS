public struct ProjectDetailResponseDTO: Codable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectId: String,
        repositoryUrl: String,
        repositoryName: String,
        repositoryImageUrl: String?,
        starCount: Int,
        techStack: [String],
        overallProgressPercent: Int,
        nextQuestionId: String?,
        sets: [ProjectSetSummaryDTO],
    ) {
        self.projectId = projectId
        self.repositoryUrl = repositoryUrl
        self.repositoryName = repositoryName
        self.repositoryImageUrl = repositoryImageUrl
        self.starCount = starCount
        self.techStack = techStack
        self.overallProgressPercent = overallProgressPercent
        self.nextQuestionId = nextQuestionId
        self.sets = sets
    }

    // MARK: Public

    public let projectId: String
    public let repositoryUrl: String
    public let repositoryName: String
    public let repositoryImageUrl: String?
    public let starCount: Int
    public let techStack: [String]
    public let overallProgressPercent: Int
    public let nextQuestionId: String?
    public let sets: [ProjectSetSummaryDTO]

}
