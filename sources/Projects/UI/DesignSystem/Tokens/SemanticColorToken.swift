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
    public static let selectedSurface = SemanticColorToken(
        name: "SelectedSurface",
        colorToken: .white5,
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
    public static let disabledText = SemanticColorToken(
        name: "DisabledText",
        colorToken: .white30,
    )

    public static let brandAccent = SemanticColorToken(
        name: "BrandAccent",
        colorToken: .blue100,
    )
    public static let progressTrack = SemanticColorToken(
        name: "ProgressTrack",
        colorToken: .grey500,
    )
    public static let progressFill = SemanticColorToken(
        name: "ProgressFill",
        colorToken: .blue200,
    )
    public static let tabBarSurface = SemanticColorToken(
        name: "TabBarSurface",
        colorToken: .blue300Alpha10,
    )
    public static let tabBarBorder = SemanticColorToken(
        name: "TabBarBorder",
        colorToken: .blue300Alpha24,
    )
    public static let grabber = SemanticColorToken(
        name: "Grabber",
        colorToken: .grey500,
    )

    public static let all: [SemanticColorToken] = [
        screenBackground,
        cardBackground,
        raisedBackground,
        accentSurface,
        selectedSurface,
        scrim,
        primaryText,
        secondaryText,
        mutedText,
        disabledText,
        brandAccent,
        progressTrack,
        progressFill,
        tabBarSurface,
        tabBarBorder,
        grabber,
    ]
}
