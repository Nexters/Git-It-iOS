public struct LearningProjectDetail: Equatable, Sendable {

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
        sets: [LearningProjectSetProgress],
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
    public let sets: [LearningProjectSetProgress]

    public var nextSet: LearningProjectSetProgress? {
        sets.first { $0.completedCount < $0.problemCount }
    }

}
