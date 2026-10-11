public struct ProjectSetSummaryDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        setID: String,
        label: String,
        title: String,
        problemCount: Int = 0,
        completedCount: Int = 0,
    ) {
        self.setID = setID
        self.label = label
        self.title = title
        self.problemCount = problemCount
        self.completedCount = completedCount
    }

    // MARK: Public

    public let setID: String
    public let label: String
    public let title: String
    public let problemCount: Int
    public let completedCount: Int

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case setID = "setId"
        case label
        case title
        case problemCount
        case completedCount
    }

}
