public struct ExternalRepository: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        canonicalURL: String,
        ownerName: String,
        repositoryName: String,
        imageURL: String?,
        starCount: Int,
        techStack: [String],
    ) {
        self.canonicalURL = canonicalURL
        self.ownerName = ownerName
        self.repositoryName = repositoryName
        self.imageURL = imageURL
        self.starCount = starCount
        self.techStack = techStack
    }

    // MARK: Public

    public let canonicalURL: String
    public let ownerName: String
    public let repositoryName: String
    public let imageURL: String?
    public let starCount: Int
    public let techStack: [String]

}
