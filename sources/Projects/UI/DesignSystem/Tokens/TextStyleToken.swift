// MARK: - TextStyleToken

public struct TextStyleToken: Sendable, Equatable {

    // MARK: Lifecycle

    public init(
        name: String,
        weight: Weight,
        size: Double,
        lineHeightPercent: Double,
        letterSpacing: Double = 0,
        paragraphSpacing: Double = 0,
        paragraphIndent: Double = 0,
    ) {
        self.name = name
        self.weight = weight
        self.size = size
        self.lineHeightPercent = lineHeightPercent
        self.letterSpacing = letterSpacing
        self.paragraphSpacing = paragraphSpacing
        self.paragraphIndent = paragraphIndent
    }

    // MARK: Public

    public let name: String
    public let weight: Weight
    public let size: Double
    public let lineHeightPercent: Double
    public let letterSpacing: Double
    public let paragraphSpacing: Double
    public let paragraphIndent: Double

}

// MARK: TextStyleToken.Weight

extension TextStyleToken {
    public enum Weight: Sendable, Equatable, Hashable {
        case bold
        case medium
        case regular
    }
}

extension TextStyleToken {
    public static let headline1 = TextStyleToken(
        name: "Headline 1",
        weight: .bold,
        size: 30,
        lineHeightPercent: 124,
    )
    public static let headline2 = TextStyleToken(
        name: "Headline 2",
        weight: .bold,
        size: 28,
        lineHeightPercent: 130,
    )
    public static let subtitle1 = TextStyleToken(
        name: "Subtitle 1",
        weight: .bold,
        size: 22,
        lineHeightPercent: 148,
    )
    public static let subtitle2 = TextStyleToken(
        name: "Subtitle 2",
        weight: .bold,
        size: 18,
        lineHeightPercent: 148,
    )
    public static let subtitle3 = TextStyleToken(
        name: "Subtitle 3",
        weight: .bold,
        size: 16,
        lineHeightPercent: 148,
    )
    public static let body1 = TextStyleToken(
        name: "Body 1",
        weight: .medium,
        size: 16,
        lineHeightPercent: 150,
    )
    public static let body2 = TextStyleToken(
        name: "Body 2",
        weight: .medium,
        size: 14,
        lineHeightPercent: 150,
    )
    public static let body3 = TextStyleToken(
        name: "Body 3",
        weight: .medium,
        size: 12,
        lineHeightPercent: 150,
    )
    public static let caption1 = TextStyleToken(
        name: "Caption 1",
        weight: .regular,
        size: 12,
        lineHeightPercent: 150,
    )
    public static let caption2 = TextStyleToken(
        name: "Caption 2",
        weight: .medium,
        size: 10,
        lineHeightPercent: 150,
    )
    public static let tabItem = TextStyleToken(
        name: "Tab Item",
        weight: .regular,
        size: 10,
        lineHeightPercent: 150,
    )
    public static let splashTitle = TextStyleToken(
        name: "Splash Title",
        weight: .bold,
        size: 44,
        lineHeightPercent: 140,
        letterSpacing: -0.98,
    )
    
    public static let splashSubtitle = TextStyleToken(
        name: "Splash Subtitle",
        weight: .bold,
        size: 22,
        lineHeightPercent: 140,
    )
    

    public static let all: [TextStyleToken] = [
        headline1,
        headline2,
        subtitle1,
        subtitle2,
        subtitle3,
        body1,
        body2,
        body3,
        caption1,
        caption2,
        tabItem,
        splashTitle,
        splashSubtitle
    ]
}
