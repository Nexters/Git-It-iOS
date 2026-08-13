import SwiftUI

extension View {
    public func designSystemBorder(_ token: BorderToken) -> some View {
        let colorToken = ColorToken.all.first { $0.name == token.colorRef }
        let color = colorToken.map { Color(designSystem: $0) } ?? Color.clear
        return overlay(Rectangle().stroke(
            color,
            lineWidth: CGFloat(token.width)
        ))
    }
}
