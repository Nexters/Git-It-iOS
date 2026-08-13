import SwiftUI

extension View {
    public func designSystemEffect(_ token: EffectToken) -> some View {
        let colorToken = ColorToken.all.first { $0.name == token.colorRef }
        let color = colorToken.map { Color(designSystem: $0) } ?? Color.clear
        return shadow(
            color: color,
            radius: CGFloat(token.blur + token.spread),
            x: CGFloat(token.offset.x),
            y: CGFloat(token.offset.y),
        )
    }
}
