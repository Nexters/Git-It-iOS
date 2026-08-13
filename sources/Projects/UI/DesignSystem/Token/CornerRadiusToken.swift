// MARK: - CornerRadiusToken

public struct CornerRadiusToken: Sendable, Equatable {
    public init(
        name: String,
        value: Double,
    ) {
        self.name = name
        self.value = value
    }

    public let name: String
    public let value: Double
}

extension CornerRadiusToken {
    public static let all = [CornerRadiusToken]()
}
