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
    public static let all = [BorderToken]()
}
