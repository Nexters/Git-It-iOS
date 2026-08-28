public struct Rubric: Equatable, Sendable {

    // MARK: Lifecycle

    public init(criteria: [String]) {
        self.criteria = criteria
    }

    // MARK: Public

    public let criteria: [String]

}
