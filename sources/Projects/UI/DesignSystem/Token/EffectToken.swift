// MARK: - EffectToken

public struct EffectToken: Sendable, Equatable {

    // MARK: Lifecycle

    public init(
        name: String,
        kind: Kind,
        colorRef: String,
        offset: Offset,
        blur: Double,
        spread: Double,
    ) {
        self.name = name
        self.kind = kind
        self.colorRef = colorRef
        self.offset = offset
        self.blur = blur
        self.spread = spread
    }

    // MARK: Public

    public let name: String
    public let kind: Kind
    public let colorRef: String
    public let offset: Offset
    public let blur: Double
    public let spread: Double

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
}

extension EffectToken {
    public static let all = [EffectToken]()
}
