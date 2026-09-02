// MARK: - BorderToken

public struct BorderToken: Sendable, Equatable {
    public init(
        name: String,
        width: Double,
        colorToken: ColorToken,
    ) {
        self.name = name
        self.width = width
        self.colorToken = colorToken
    }

    public let name: String
    public let width: Double
    public let colorToken: ColorToken
}

extension BorderToken {
    public static let `default` = BorderToken(
        name: "Default",
        width: 1,
        colorToken: .grey500,
    )
    public static let focus = BorderToken(
        name: "Focus",
        width: 1,
        colorToken: .blue100,
    )
    public static let highlight = BorderToken(
        name: "Highlight",
        width: 1,
        colorToken: .blue200,
    )
    public static let error = BorderToken(
        name: "Error",
        width: 1,
        colorToken: .error,
    )
    public static let tabBar = BorderToken(
        name: "TabBar",
        width: 1,
        colorToken: .blue300Alpha24,
    )
    public static let loadingTrack = BorderToken(
        name: "LoadingTrack",
        width: 4,
        colorToken: .grey400,
    )

    public static let all = [`default`, focus, highlight, error, tabBar, loadingTrack]
}
