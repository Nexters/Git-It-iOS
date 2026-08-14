import SwiftUI

extension View {
    public func designSystemForeground(_ token: ColorToken) -> some View {
        foregroundStyle(Color(designSystem: token))
    }

    public func designSystemBackground(_ token: ColorToken) -> some View {
        background(Color(designSystem: token))
    }
}

extension Color {
    public init(designSystem token: ColorToken) {
        self.init(
            designSystemHex: token.hex,
            opacityPercent: token.opacityPercent,
        )
    }

    init(
        designSystemHex hex: String,
        opacityPercent: Double? = nil,
    ) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let red = Double((value & 0xFF0000) >> 16) / 255
        let green = Double((value & 0x00FF00) >> 8) / 255
        let blue = Double(value & 0x0000FF) / 255
        let alpha = (opacityPercent.map { $0 / 100 }) ?? 1
        self.init(
            .sRGB,
            red: red,
            green: green,
            blue: blue,
            opacity: alpha,
        )
    }
}
