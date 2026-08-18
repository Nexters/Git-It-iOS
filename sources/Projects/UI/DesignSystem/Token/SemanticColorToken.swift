// MARK: - SemanticColorToken

public struct SemanticColorToken: Sendable, Equatable {
    public init(
        name: String,
        colorToken: ColorToken,
    ) {
        self.name = name
        self.colorToken = colorToken
    }

    public let name: String
    public let colorToken: ColorToken
}

extension SemanticColorToken {
    public static let screenBackground = SemanticColorToken(
        name: "ScreenBackground",
        colorToken: .grey700,
    )
    public static let cardBackground = SemanticColorToken(
        name: "CardBackground",
        colorToken: .grey600,
    )
    public static let raisedBackground = SemanticColorToken(
        name: "RaisedBackground",
        colorToken: .grey500,
    )
    public static let accentSurface = SemanticColorToken(
        name: "AccentSurface",
        colorToken: .blue500,
    )
    public static let scrim = SemanticColorToken(
        name: "Scrim",
        colorToken: .black70,
    )

    public static let primaryText = SemanticColorToken(
        name: "PrimaryText",
        colorToken: .grey100,
    )
    public static let secondaryText = SemanticColorToken(
        name: "SecondaryText",
        colorToken: .grey300,
    )
    public static let mutedText = SemanticColorToken(
        name: "MutedText",
        colorToken: .grey400,
    )

    public static let brandAccent = SemanticColorToken(
        name: "BrandAccent",
        colorToken: .blue100,
    )

    public static let all: [SemanticColorToken] = [
        screenBackground,
        cardBackground,
        raisedBackground,
        accentSurface,
        scrim,
        primaryText,
        secondaryText,
        mutedText,
        brandAccent,
    ]
}
