public struct GitHubRepositoryResponseDTO: Codable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        fullName: String,
        htmlURL: String,
        ownerAvatarURL: String?,
        starCount: Int,
        language: String?,
        topics: [String],
    ) {
        self.fullName = fullName
        self.htmlURL = htmlURL
        self.ownerAvatarURL = ownerAvatarURL
        self.starCount = starCount
        self.language = language
        self.topics = topics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fullName = try container.decode(String.self, forKey: .fullName)
        htmlURL = try container.decode(String.self, forKey: .htmlURL)
        starCount = try container.decode(Int.self, forKey: .starCount)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        topics = try container.decodeIfPresent([String].self, forKey: .topics) ?? []

        let ownerContainer = try container.nestedContainer(keyedBy: OwnerCodingKeys.self, forKey: .owner)
        ownerAvatarURL = try ownerContainer.decodeIfPresent(String.self, forKey: .avatarURL)
    }

    // MARK: Public

    public let fullName: String
    public let htmlURL: String
    public let ownerAvatarURL: String?
    public let starCount: Int
    public let language: String?
    public let topics: [String]

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(htmlURL, forKey: .htmlURL)
        try container.encode(starCount, forKey: .starCount)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encode(topics, forKey: .topics)

        var ownerContainer = container.nestedContainer(keyedBy: OwnerCodingKeys.self, forKey: .owner)
        try ownerContainer.encodeIfPresent(ownerAvatarURL, forKey: .avatarURL)
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case htmlURL = "html_url"
        case owner
        case starCount = "stargazers_count"
        case language
        case topics
    }

    private enum OwnerCodingKeys: String, CodingKey {
        case avatarURL = "avatar_url"
    }

}
