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

    /// 미완료 세트가 있으면 첫 미완료 세트, 모두 완료했으면 replay를 위해 `sets.first`로
    /// fallback한다. `sets`가 비어 있으면 nil이다(GAP-014-006).
    public var nextSet: LearningProjectSetProgress? {
        sets.first { $0.completedCount < $0.problemCount } ?? sets.first
    }

}
