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
        case repositoryName = "projectName"
    }
}

// MARK: - BookmarkedQuestionResponseDTO

public struct BookmarkedQuestionResponseDTO: Decodable, Equatable, Sendable {
    public init(
        projectID: String,
        projectName: String = "",
        setID: String,
        setLabel: String = "",
        problemNumber: Int = 0,
        questionID: String,
        question: String = "",
    ) {
        self.projectID = projectID
        self.projectName = projectName
        self.setID = setID
        self.setLabel = setLabel
        self.problemNumber = problemNumber
        self.questionID = questionID
        self.question = question
    }

    public let projectID: String
    public let projectName: String
    public let setID: String
    public let setLabel: String
    public let problemNumber: Int
    public let questionID: String
    public let question: String

    private enum CodingKeys: String, CodingKey {
        case projectID = "projectId"
        case projectName
        case setID = "setId"
        case setLabel
        case problemNumber
        case questionID = "questionId"
        case question
    }
}
