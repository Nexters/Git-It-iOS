public struct GitHubRepositoryResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        htmlURL: String,
        ownerAvatarURL: String?,
        starCount: Int,
        topics: [String],
    ) {
        self.htmlURL = htmlURL
        self.ownerAvatarURL = ownerAvatarURL
        self.starCount = starCount
        self.topics = topics
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let owner = try container.nestedContainer(keyedBy: OwnerCodingKeys.self, forKey: .owner)
        htmlURL = try container.decode(String.self, forKey: .htmlURL)
        ownerAvatarURL = try owner.decodeIfPresent(String.self, forKey: .avatarURL)
        starCount = try container.decode(Int.self, forKey: .starCount)
        topics = try container.decodeIfPresent([String].self, forKey: .topics) ?? []
    }

    // MARK: Public

    public let htmlURL: String
    public let ownerAvatarURL: String?
    public let starCount: Int
    public let topics: [String]

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case htmlURL = "html_url"
        case owner
        case starCount = "stargazers_count"
        case topics
    }

    private enum OwnerCodingKeys: String, CodingKey { case avatarURL = "avatar_url" }

}
