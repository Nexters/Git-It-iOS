import DomainIdentifier

public struct ProjectSummary: Equatable, Identifiable, Sendable {

    // MARK: Lifecycle

    public init(
        id: ProjectID,
        repositoryName: String,
        repositoryImageURL: String?,
        techStack: [String],
        currentSet: ProjectSetLabel,
        next: ProjectNextQuiz?,
        progressPercent: Int,
    ) {
        self.id = id
        self.repositoryName = repositoryName
        self.repositoryImageURL = repositoryImageURL
        self.techStack = techStack
        self.currentSet = currentSet
        self.next = next
        self.progressPercent = progressPercent
    }

    // MARK: Public

    public let id: ProjectID
    public let repositoryName: String
    public let repositoryImageURL: String?
    public let techStack: [String]
    public let currentSet: ProjectSetLabel
    public let next: ProjectNextQuiz?
    public let progressPercent: Int

}
