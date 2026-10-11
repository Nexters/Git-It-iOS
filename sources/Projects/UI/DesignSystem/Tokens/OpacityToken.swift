// MARK: - OpacityToken

public struct OpacityToken: Sendable, Equatable {
    public init(
        name: String,
        percent: Double,
    ) {
        self.name = name
        self.percent = percent
    }

    public let name: String
    public let percent: Double
}

extension OpacityToken {
    public static let subtleSurface = OpacityToken(
        name: "SubtleSurface",
        percent: 5,
    )
    public static let tabSurface = OpacityToken(
        name: "TabSurface",
        percent: 10,
    )
    public static let track = OpacityToken(
        name: "Track",
        percent: 15,
    )
    public static let border = OpacityToken(
        name: "Border",
        percent: 24,
    )
    public static let disabled = OpacityToken(
        name: "Disabled",
        percent: 30,
    )
    public static let scrim = OpacityToken(
        name: "Scrim",
        percent: 70,
    )

    public static let all = [subtleSurface, tabSurface, track, border, disabled, scrim]
}
