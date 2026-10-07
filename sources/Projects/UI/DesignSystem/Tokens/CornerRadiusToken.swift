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
    public static let micro = CornerRadiusToken(
        name: "Micro",
        value: 3,
    )
    public static let compact = CornerRadiusToken(
        name: "Compact",
        value: 6,
    )
    public static let small = CornerRadiusToken(
        name: "Small",
        value: 8,
    )
    public static let medium = CornerRadiusToken(
        name: "Medium",
        value: 10,
    )
    public static let large = CornerRadiusToken(
        name: "Large",
        value: 12,
    )
    public static let extraLarge = CornerRadiusToken(
        name: "ExtraLarge",
        value: 16,
    )
    public static let pill = CornerRadiusToken(
        name: "Pill",
        value: 999,
    )

    public static let all: [CornerRadiusToken] = [micro, compact, small, medium, large, extraLarge, pill]
}
