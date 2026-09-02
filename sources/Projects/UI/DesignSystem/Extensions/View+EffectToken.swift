import SwiftUI

extension View {
    public func designSystemEffect(_ token: EffectToken) -> some View {
        modifier(DesignSystemEffectModifier(token: token))
    }
}

private struct DesignSystemEffectModifier: ViewModifier {
    let token: EffectToken

    func body(content: Content) -> some View {
        token.layers.reduce(AnyView(content)) { view, layer in
            AnyView(view.shadow(
                color: Color(designSystem: layer.colorToken),
                radius: CGFloat(layer.blur / 2 + layer.spread),
                x: CGFloat(layer.offset.x),
                y: CGFloat(layer.offset.y),
            ))
        }
    }
}
