public struct LearningSetMark: Sendable, Equatable {
    public init(
        order: Int,
        title: String,
    ) {
        self.order = max(order, 1)
        self.title = title
    }

    public let order: Int
    public let title: String
}
