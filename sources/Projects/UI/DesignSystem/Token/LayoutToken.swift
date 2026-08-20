// MARK: - LayoutToken

public struct LayoutToken: Sendable, Equatable {
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

extension LayoutToken {
    public static let margin = LayoutToken(
        name: "Margin",
        value: 20,
    )
    public static let gutter = LayoutToken(
        name: "Gutter",
        value: 12,
    )
    public static let compactSpacing = LayoutToken(
        name: "CompactSpacing",
        value: 8,
    )

    public static let all: [LayoutToken] = [margin, gutter, compactSpacing]
}
