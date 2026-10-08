public struct ProjectDetail: Equatable, Identifiable, Sendable {

    // MARK: Lifecycle

    public init(
        id: ProjectID,
        repository: ProjectRepositoryInfo,
        progressPercent: Int,
        sets: [ProjectSetProgress],
        next: ProjectNextQuiz?,
    ) {
        self.id = id
        self.repository = repository
        self.progressPercent = progressPercent
        self.sets = sets
        self.next = next
    }

    // MARK: Public

    public let id: ProjectID
    public let repository: ProjectRepositoryInfo
    public let progressPercent: Int
    public let sets: [ProjectSetProgress]
    public let next: ProjectNextQuiz?

}
