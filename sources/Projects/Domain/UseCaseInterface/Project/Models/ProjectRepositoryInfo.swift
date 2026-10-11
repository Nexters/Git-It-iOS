public struct ProjectRepositoryInfo: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        url: String,
        name: String,
        imageURL: String?,
        starCount: Int,
        techStack: [String],
    ) {
        self.url = url
        self.name = name
        self.imageURL = imageURL
        self.starCount = starCount
        self.techStack = techStack
    }

    // MARK: Public

    public let url: String
    public let name: String
    public let imageURL: String?
    public let starCount: Int
    public let techStack: [String]

}
