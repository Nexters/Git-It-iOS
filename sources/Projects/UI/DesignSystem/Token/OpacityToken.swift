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
    public static let all = [OpacityToken]()
}
