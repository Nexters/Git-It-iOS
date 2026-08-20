public struct LearningProjectDetail: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectId: String,
        repositoryURL: String,
        repositoryName: String,
        repositoryImageURL: String?,
        starCount: Int,
        techStack: [String],
        overallProgressPercent: Int,
        nextQuestionId: String?,
        sets: [LearningProjectSetProgress],
    ) {
        self.projectId = projectId
        self.repositoryURL = repositoryURL
        self.repositoryName = repositoryName
        self.repositoryImageURL = repositoryImageURL
        self.starCount = starCount
        self.techStack = techStack
        self.overallProgressPercent = overallProgressPercent
        self.nextQuestionId = nextQuestionId
        self.sets = sets
    }

    // MARK: Public

    public let projectId: String
    public let repositoryURL: String
    public let repositoryName: String
    public let repositoryImageURL: String?
    public let starCount: Int
    public let techStack: [String]
    public let overallProgressPercent: Int
    public let nextQuestionId: String?
    public let sets: [LearningProjectSetProgress]

    public var nextSet: LearningProjectSetProgress? {
        sets.first { $0.completedCount < $0.problemCount }
    }

}
