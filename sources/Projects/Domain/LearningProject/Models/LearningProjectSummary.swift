public struct LearningProjectSummary: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectId: String,
        repositoryName: String,
        repositoryImageURL: String?,
        techStack: [String],
        currentSetLabel: String,
        currentSetTitle: String,
        nextSetId: String,
        nextQuestionId: String,
        overallProgressPercent: Int,
    ) {
        self.projectId = projectId
        self.repositoryName = repositoryName
        self.repositoryImageURL = repositoryImageURL
        self.techStack = techStack
        self.currentSetLabel = currentSetLabel
        self.currentSetTitle = currentSetTitle
        self.nextSetId = nextSetId
        self.nextQuestionId = nextQuestionId
        self.overallProgressPercent = overallProgressPercent
    }

    // MARK: Public

    public let projectId: String
    public let repositoryName: String
    public let repositoryImageURL: String?
    public let techStack: [String]
    public let currentSetLabel: String
    public let currentSetTitle: String
    public let nextSetId: String
    public let nextQuestionId: String
    public let overallProgressPercent: Int

}
