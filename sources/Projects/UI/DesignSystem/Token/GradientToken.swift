// MARK: - GradientToken

public struct GradientToken: Sendable, Equatable {
    public init(
        name: String,
        start: UnitPointRatio,
        end: UnitPointRatio,
        stops: [Stop],
    ) {
        self.name = name
        self.start = start
        self.end = end
        self.stops = stops
    }

    public let name: String
    public let start: UnitPointRatio
    public let end: UnitPointRatio
    public let stops: [Stop]
}

extension GradientToken {
    public struct UnitPointRatio: Sendable, Equatable {
        public init(
            x: Double,
            y: Double,
        ) {
            self.x = x
            self.y = y
        }

        public let x: Double
        public let y: Double
    }

    public struct Stop: Sendable, Equatable {
        public init(
            position: Double,
            hex: String,
        ) {
            self.position = position
            self.hex = hex
        }

        public let position: Double
        public let hex: String
    }
}

extension GradientToken {

    // MARK: Public

    public static let gradient1 = GradientToken(
        name: "Gradient 1",
        start: topToBottomStart,
        end: topToBottomEnd,
        stops: [
            Stop(
                position: 0,
                hex: "#3B3749",
            ),
            Stop(
                position: 1,
                hex: "#56718A",
            ),
        ],
    )

    public static let gradient2 = GradientToken(
        name: "Gradient 2",
        start: topToBottomStart,
        end: topToBottomEnd,
        stops: [
            Stop(
                position: 0,
                hex: "#141414",
            ),
            Stop(
                position: 1,
                hex: "#A5C4F0",
            ),
        ],
    )

    public static let gradient3 = GradientToken(
        name: "Gradient 3",
        start: topToBottomStart,
        end: topToBottomEnd,
        stops: [
            Stop(
                position: 0,
                hex: "#82ACE5",
            ),
            Stop(
                position: 1,
                hex: "#D5E7FE",
            ),
        ],
    )

    public static let all: [GradientToken] = [gradient1, gradient2, gradient3]

    // MARK: Private

    private static let topToBottomStart = UnitPointRatio(
        x: 0.5,
        y: 0,
    )
    private static let topToBottomEnd = UnitPointRatio(
        x: 0.5,
        y: 1,
    )

}
