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
    public static let tightSpacing = LayoutToken(
        name: "TightSpacing",
        value: 4,
    )
    public static let iconSpacing = LayoutToken(
        name: "IconSpacing",
        value: 6,
    )
    public static let cardHorizontalPadding = LayoutToken(
        name: "CardHorizontalPadding",
        value: 18,
    )
    public static let cardTopPadding = LayoutToken(
        name: "CardTopPadding",
        value: 14,
    )

    public static let all: [LayoutToken] = [
        margin,
        gutter,
        compactSpacing,
        tightSpacing,
        iconSpacing,
        cardHorizontalPadding,
        cardTopPadding,
    ]
}
