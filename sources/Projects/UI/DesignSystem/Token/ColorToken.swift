// MARK: - ColorToken

public struct ColorToken: Sendable, Equatable {
    public init(
        name: String,
        group: Group,
        hex: String,
        opacityPercent: Double? = nil,
    ) {
        self.name = name
        self.group = group
        self.hex = hex
        self.opacityPercent = opacityPercent
    }

    public let name: String
    public let group: Group
    public let hex: String
    public let opacityPercent: Double?
}

// MARK: ColorToken.Group

extension ColorToken {
    public enum Group: String, Sendable, CaseIterable {
        case blue = "Blue"
        case purple = "Purple"
        case grey = "Grey"
        case opacity = "Opacity"
        case state = "State"
    }
}

extension ColorToken {
    public static let clear = ColorToken(
        name: "Clear",
        group: .opacity,
        hex: "#000000",
        opacityPercent: 0,
    )

    public static let white = ColorToken(
        name: "White",
        group: .opacity,
        hex: "#FFFFFF",
    )

    public static let blue500 = ColorToken(
        name: "Blue500",
        group: .blue,
        hex: "#2F3853",
    )
    public static let blue400 = ColorToken(
        name: "Blue400",
        group: .blue,
        hex: "#506381",
    )
    public static let blue300 = ColorToken(
        name: "Blue300",
        group: .blue,
        hex: "#7E94BB",
    )
    public static let blue200 = ColorToken(
        name: "Blue200",
        group: .blue,
        hex: "#8BB5EF",
    )
    public static let blue100 = ColorToken(
        name: "Blue100",
        group: .blue,
        hex: "#B9D6FE",
    )

    public static let purple500 = ColorToken(
        name: "Purple500",
        group: .purple,
        hex: "#3B3749",
    )
    public static let purple400 = ColorToken(
        name: "Purple400",
        group: .purple,
        hex: "#585B6F",
    )
    public static let purple300 = ColorToken(
        name: "Purple300",
        group: .purple,
        hex: "#898DA6",
    )
    public static let purple200 = ColorToken(
        name: "Purple200",
        group: .purple,
        hex: "#A4A9C7",
    )
    public static let purple100 = ColorToken(
        name: "Purple100",
        group: .purple,
        hex: "#BDC2DC",
    )

    public static let grey700 = ColorToken(
        name: "Grey700",
        group: .grey,
        hex: "#141414",
    )
    public static let grey600 = ColorToken(
        name: "Grey600",
        group: .grey,
        hex: "#242425",
    )
    public static let grey500 = ColorToken(
        name: "Grey500",
        group: .grey,
        hex: "#3B3B3B",
    )
    public static let grey400 = ColorToken(
        name: "Grey400",
        group: .grey,
        hex: "#919191",
    )
    public static let grey300 = ColorToken(
        name: "Grey300",
        group: .grey,
        hex: "#BCBCBC",
    )
    public static let grey200 = ColorToken(
        name: "Grey200",
        group: .grey,
        hex: "#ECECEC",
    )
    public static let grey100 = ColorToken(
        name: "Grey100",
        group: .grey,
        hex: "#FFFFFF",
    )

    public static let white5 = ColorToken(
        name: "white 5",
        group: .opacity,
        hex: "#FFFFFF",
        opacityPercent: 5,
    )
    public static let white15 = ColorToken(
        name: "white 15",
        group: .opacity,
        hex: "#FFFFFF",
        opacityPercent: 15,
    )
    public static let white30 = ColorToken(
        name: "white 30",
        group: .opacity,
        hex: "#FFFFFF",
        opacityPercent: 30,
    )
    public static let white70 = ColorToken(
        name: "white 70",
        group: .opacity,
        hex: "#FFFFFF",
        opacityPercent: 70,
    )
    public static let black70 = ColorToken(
        name: "Black 70",
        group: .opacity,
        hex: "#000000",
        opacityPercent: 70,
    )

    public static let error = ColorToken(
        name: "Error",
        group: .state,
        hex: "#FF3721",
    )
    public static let correct = ColorToken(
        name: "Correct",
        group: .state,
        hex: "#3E85FF",
    )
    public static let incorrect = ColorToken(
        name: "Incorrect",
        group: .state,
        hex: "#FF5656",
    )
    public static let caution = ColorToken(
        name: "Caution",
        group: .state,
        hex: "#ECBD23",
    )
    public static let success = ColorToken(
        name: "Success",
        group: .state,
        hex: "#249900",
    )

    public static let all: [ColorToken] = [
        clear,
        white,
        blue500,
        blue400,
        blue300,
        blue200,
        blue100,
        purple500,
        purple400,
        purple300,
        purple200,
        purple100,
        grey700,
        grey600,
        grey500,
        grey400,
        grey300,
        grey200,
        grey100,
        white5,
        white15,
        white30,
        white70,
        black70,
        error,
        correct,
        incorrect,
        caution,
        success,
    ]
}
