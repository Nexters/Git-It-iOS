public struct LearningProjectID: Sendable, Hashable, Identifiable {
    public init?(rawValue: String) {
        guard !rawValue.allSatisfy(\.isWhitespace) else {
            return nil
        }

        self.rawValue = rawValue
    }

    public let rawValue: String

    public var id: Self {
        self
    }
}
