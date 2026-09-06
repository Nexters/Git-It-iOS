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
            opacity: Double = 1,
        ) {
            self.position = position
            self.hex = hex
            self.opacity = opacity
        }

        public let position: Double
        public let hex: String
        public let opacity: Double
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

    public static let backgroundGradient = GradientToken(
        name: "BackgroundGradientGradient",
        start: .init(x: 0.5, y: 0.6868),
        end: .init(x: 0.5, y: 1.79211),
        stops: GradientToken.gradient2.stops,
    )

    public static let topEdgeScrim = GradientToken(
        name: "TopEdgeScrim",
        start: topToBottomEnd,
        end: topToBottomStart,
        stops: [
            Stop(
                position: 0,
                hex: "#141414",
                opacity: 0,
            ),
            Stop(
                position: 1,
                hex: "#141414",
                opacity: 0.5,
            ),
        ],
    )

    public static let quizTopScrim = GradientToken(
        name: "QuizTopScrim",
        start: topToBottomEnd,
        end: topToBottomStart,
        stops: [
            Stop(
                position: 0,
                hex: "#141414",
                opacity: 0,
            ),
            Stop(
                position: 0.25,
                hex: "#141414",
                opacity: 0.5,
            ),
        ],
    )
    public static let bottomEdgeScrim = GradientToken(
        name: "BottomEdgeScrim",
        start: topToBottomStart,
        end: topToBottomEnd,
        stops: [
            Stop(
                position: 1,
                hex: "#141414",
                opacity: 0,
            ),
            Stop(
                position: 0.2,
                hex: "#141414",
                opacity: 0.6,
            ),
        ],
    )

    public static let overlayHeaderScrim = GradientToken(
        name: "OverlayHeaderScrim",
        start: topToBottomStart,
        end: topToBottomEnd,
        stops: [
            Stop(
                position: 0,
                hex: "#141414",
                opacity: 0.6,
            ),
            Stop(
                position: 0.65,
                hex: "#141414",
                opacity: 0.2,
            ),
            Stop(
                position: 1,
                hex: "#141414",
                opacity: 0,
            ),
        ],
    )

    public static let overlayFooterScrim = GradientToken(
        name: "OverlayFooterScrim",
        start: topToBottomStart,
        end: topToBottomEnd,
        stops: [
            Stop(
                position: 0,
                hex: "#141414",
                opacity: 0,
            ),
            Stop(
                position: 0.2,
                hex: "#141414",
                opacity: 0.8,
            ),
            Stop(
                position: 1,
                hex: "#141414",
                opacity: 1,
            ),
        ],
    )

    public static let all: [GradientToken] = [
        gradient1,
        gradient2,
        gradient3,
        topEdgeScrim,
        bottomEdgeScrim,
    ]

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
