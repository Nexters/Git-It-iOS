// MARK: - EffectToken

public struct EffectToken: Sendable, Equatable {

    // MARK: Lifecycle

    public init(
        name: String,
        kind: Kind,
        layers: [Layer],
    ) {
        self.name = name
        self.kind = kind
        self.layers = layers
    }

    // MARK: Public

    public let name: String
    public let kind: Kind
    public let layers: [Layer]

}

extension EffectToken {
    public enum Kind: Sendable, Equatable {
        case dropShadow
        case innerShadow
    }

    public struct Offset: Sendable, Equatable {
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

    public struct Layer: Sendable, Equatable {
        public init(
            colorToken: ColorToken,
            offset: Offset,
            blur: Double,
            spread: Double = 0,
        ) {
            self.colorToken = colorToken
            self.offset = offset
            self.blur = blur
            self.spread = spread
        }

        public let colorToken: ColorToken
        public let offset: Offset
        public let blur: Double
        public let spread: Double
    }
}

extension EffectToken {
    public static let sheetElevation = EffectToken(
        name: "SheetElevation",
        kind: .dropShadow,
        layers: [
            Layer(
                colorToken: .black45,
                offset: Offset(x: 0, y: 4),
                blur: 6,
            ),
            Layer(
                colorToken: .black35,
                offset: Offset(x: 0, y: 4),
                blur: 34,
            ),
        ],
    )
    public static let cardElevation = EffectToken(
        name: "CardElevation",
        kind: .dropShadow,
        layers: [
            Layer(
                colorToken: .black25,
                offset: Offset(x: 4, y: 4),
                blur: 15,
                spread: 10,
            ),
        ],
    )

    public static let all = [sheetElevation, cardElevation]
}
