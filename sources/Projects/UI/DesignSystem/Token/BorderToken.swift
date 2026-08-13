// MARK: - BorderToken

public struct BorderToken: Sendable, Equatable {
    public init(
        name: String,
        width: Double,
        colorRef: String,
    ) {
        self.name = name
        self.width = width
        self.colorRef = colorRef
    }

    public let name: String
    public let width: Double
    public let colorRef: String
}

extension BorderToken {
    public static let all = [BorderToken]()
}
