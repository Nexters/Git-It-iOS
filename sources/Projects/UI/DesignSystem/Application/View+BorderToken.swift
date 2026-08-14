import SwiftUI

extension View {
    public func designSystemBorder(_ token: BorderToken) -> some View {
        let color = Color(designSystem: token.colorToken)
        return overlay(Rectangle().stroke(
            color,
            lineWidth: CGFloat(token.width),
        ))
    }
}
