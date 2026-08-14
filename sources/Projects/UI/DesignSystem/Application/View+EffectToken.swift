import SwiftUI

extension View {
    public func designSystemEffect(_ token: EffectToken) -> some View {
        let color = Color(designSystem: token.colorToken)
        return shadow(
            color: color,
            radius: CGFloat(token.blur + token.spread),
            x: CGFloat(token.offset.x),
            y: CGFloat(token.offset.y),
        )
    }
}
