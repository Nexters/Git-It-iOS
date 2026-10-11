// MARK: - ControlSizeToken

public struct ControlSizeToken: Sendable, Equatable {
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

extension ControlSizeToken {
    public static let action = ControlSizeToken(
        name: "Action",
        value: 54,
    )
    public static let minimumTouch = ControlSizeToken(
        name: "MinimumTouch",
        value: 44,
    )

    public static let all: [ControlSizeToken] = [action, minimumTouch]
}
