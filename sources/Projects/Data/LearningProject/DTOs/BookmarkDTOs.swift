// MARK: - BookmarkQuestionRequestDTO

public struct BookmarkQuestionRequestDTO: Encodable, Equatable, Sendable {
    public init(bookmarked: Bool) {
        self.bookmarked = bookmarked
    }

    public let bookmarked: Bool
}

// MARK: - BookmarkQuestionResponseDTO

public struct BookmarkQuestionResponseDTO: Decodable, Equatable, Sendable {
    public init(bookmarked: Bool) {
        self.bookmarked = bookmarked
    }

    public let bookmarked: Bool
}

// MARK: - BookmarkedQuestionListResponseDTO

public struct BookmarkedQuestionListResponseDTO: Decodable, Equatable, Sendable {
    public init(
        totalCount: Int,
        availableProjects: [AvailableProjectResponseDTO],
        bookmarks: [BookmarkedQuestionResponseDTO],
    ) {
        self.totalCount = totalCount
        self.availableProjects = availableProjects
        self.bookmarks = bookmarks
    }

    public let totalCount: Int
    public let availableProjects: [AvailableProjectResponseDTO]
    public let bookmarks: [BookmarkedQuestionResponseDTO]
}

// MARK: - AvailableProjectResponseDTO

public struct AvailableProjectResponseDTO: Decodable, Equatable, Sendable {
    public init(
        projectID: String,
        repositoryName: String,
    ) {
        self.projectID = projectID
        self.repositoryName = repositoryName
    }

    public let projectID: String
    public let repositoryName: String

    private enum CodingKeys: String, CodingKey {
        case projectID = "projectId"
        case repositoryName
    }
}

// MARK: - BookmarkedQuestionResponseDTO

public struct BookmarkedQuestionResponseDTO: Decodable, Equatable, Sendable {
    public init(
        projectID: String,
        setID: String,
        questionID: String,
    ) {
        self.projectID = projectID
        self.setID = setID
        self.questionID = questionID
    }

    public let projectID: String
    public let setID: String
    public let questionID: String

    private enum CodingKeys: String, CodingKey {
        case projectID = "projectId"
        case setID = "setId"
        case questionID = "questionId"
    }
}
